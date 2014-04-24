# -*- coding: utf-8 -*-
from __future__ import unicode_literals

import ConfigParser
import glob
import os
import shutil
import sys
import logging

import jinja2
from fabric.api import local, settings, task, lcd


logging.basicConfig(level=logging.INFO, format='%(msg)s')


class CircularDependencyError(Exception):
    pass


def _resolve_dependencies(available_sections, required_sections,
                          section, seen=None):
    if seen is None and section is not None:
        seen = set([section])
    requirements = []

    for requirement in required_sections:
        next_requirements = available_sections[requirement]
        if requirement in seen:
            raise CircularDependencyError
        r = _resolve_dependencies(
            available_sections,
            next_requirements,
            requirement,
            seen=seen,
        )
        requirements.extend([req for req in r if req not in requirements])
    requirements.append(section)
    return requirements


def _render_template(template, context):

    with open(template) as tpl:
        template = tpl.read()

    template = jinja2.Template(template)
    return template.render(**context)


def _get_template_context(*args):
    context = {}
    for var in args:
        confirmed = False
        while not confirmed:
            context[var] = raw_input('Enter {0} :\t'.format(var))
            answer = raw_input(
                'Got {0}. Is this correct? [Yn]\t'.format(context[var]))
            if not answer or answer.lower().startswith('y'):
                confirmed = True
    return context


def _create_backup(dst):
    if os.path.exists(dst):
        backup = backup_orig = '{0}.backup'.format(dst.rstrip('/'))
        logging.info('Creating backup of {0} at {1}'.format(dst, backup))

        i = 1
        while os.path.exists(backup):
            backup = '{0}.{1}'.format(backup_orig, i)
            i += 1

        try:
            os.rename(dst.rstrip('/'), backup)
        except:
            logging.exception('Couldn\'t create backup, aborting...')
            exit(1)
        else:
            return backup
    return False


def _install_file(method, src, dst, *args, **kwargs):
    backup = False
    failure = False
    dirname = os.path.dirname(dst)
    if not os.path.isdir(dirname):
        logging.info('Creating directory: {0}'.format(dirname))
        os.makedirs(dirname)
    if os.path.exists(dst):
        action = raw_input('{0} exists? [B]ackup [o]verwrite '
                           '[c]ancel [a]bort\t'.format(dst))
        if action.lower().startswith('o'):
            logging.info('Overwriting {0} with {1}.'.format(dst, src))
            logging.info('Removing {0}'.format(dst))
            try:
                os.remove(dst)
            except OSError:
                shutil.rmtree(dst)
        elif action.lower().startswith('c'):
            logging.info('Not installing {0}.'.format(src))
            return
        elif action.lower().startswith('a'):
            logging.info('Aborting...')
            exit(1)
        else:
            backup = _create_backup(dst)
    if method == 'template':
        if 'context' in kwargs:
            context = kwargs.get('context')
        elif args:
            context = args[0]
        else:
            context = []
        if isinstance(context, basestring):
            context = context.split(',')
        context = _get_template_context(*context)
        content = _render_template(src, context)
        try:
            logging.debug('Writing template to {0}'.format(dst))
            with open(dst, 'w') as f:
                f.write(content)
        except:
            failure = True
    elif method == 'link':
        try:
            logging.debug('Linking {0} to {1}'
                          .format(src.rstrip('/'), dst.rstrip('/')))
            os.symlink(src.rstrip('/'), dst.rstrip('/'))
        except:
            failure = True
    elif method == 'copy':
        try:
            logging.debug('Copying {0} to {1}'
                          .format(src.rstrip('/'), dst.rstrip('/')))
            shutil.copy2(src, dst)
        except:
            failure = True
    else:
        logging.info('{0}? {0}? WTF is {0}?'.format(method))
    if failure:
        if not backup:
            logging.error('Failed to write {0}'.format(src))
        else:
            logging.info('Failed to write {0}, attempting to restore '
                         'from backup...'.format(src))
            try:
                os.rename(backup, dst)
                logging.info('Restored')
            except:
                logging.error('Failed to restore backup {0}. '
                              'Aborting...'.format(backup))
                exit(1)


@task
def install(*args, **kwargs):
    '''
    Install dotfile sections.

    Optionally pass in the name of a section to only install that section.
    '''
    global install

    from_section = kwargs.get('from_section', None)

    init = str(kwargs.get('init', 'true')).lower() \
        in ['t', 'true', 'y', 'yes', '1']
    if init:
        local('git submodule update --init > /dev/null')

    if str(kwargs.get('submodules', 'n')).lower() \
            in ['t', 'true', 'y', 'yes', '1']:
        update_submodules()

    upgrade = str(kwargs.get('upgrade', 'n')).lower() \
        in ['t', 'true', 'y', 'yes', '1']

    basedir = os.path.dirname(__file__)
    config = ConfigParser.ConfigParser()
    config.read(os.path.join(basedir, 'dotfiles.conf'))
    available_sections = dict(
        (
            section,
            config.get(section, 'depends').split(',')
            if config.has_option(section, 'depends') else []
        ) for section in config.sections()
    )
    sections = []
    if args:
        for s in args:
            s = s.strip()
            if s in config.sections():
                sections.append(s)
            else:
                found = False
                for type in ['files', 'installer', 'script']:
                    if ':'.join([type, s]) in config.sections():
                        sections.append(':'.join([type, s]))
                        found = True
                        break
                if not found:
                    raise Exception('Could not find section {0}'.format(s))
    else:
        sections = config.sections()

    installed = kwargs.pop('installed', [])
    for section in sections:
        if section in installed:
            continue
        requirements = _resolve_dependencies(available_sections,
                                             available_sections[section],
                                             section)
        for requirement in requirements:
            if requirement != section:
                try:
                    install(requirement, installed=installed,
                            init=False, from_section=section)
                except TypeError:
                    pass
        installed.append(section)
        if ':' in section:
            stype, section_name = section.split(':')
        else:
            stype, section_name = 'file', section
        if from_section is not None:
            logging.info('{0} is a requirement of {1}...'
                         .format(section, from_section))
        do_install = raw_input('Install {0}? [Yn]\t'.format(section_name))
        if do_install and not do_install.lower().startswith('y'):
            continue
        if stype == 'files':
            sectiondir = os.path.join(basedir, section_name).rstrip('/')
            pre_install = os.path.join(sectiondir, 'dotfile.pre_install')
            if os.path.exists(pre_install) and os.access(pre_install, os.X_OK):
                local(pre_install)

            try:
                links = config.get(section, 'link')
            except ConfigParser.NoOptionError:
                links = ''

            if links == '*':
                links = glob.glob(os.path.join(sectiondir, '*'))
                links.extend(glob.glob(os.path.join(sectiondir, '.*')))
            else:
                links = [os.path.join(sectiondir, f)
                         for f in links.split(',') if f]

            try:
                copies = config.get(section, 'copy')
            except ConfigParser.NoOptionError:
                copies = ''

            if copies == '*':
                copies = glob.glob(os.path.join(sectiondir, '*'))
                copies.extend(glob.glob(os.path.join(sectiondir, '.*')))
            else:
                copies = [os.path.join(sectiondir, f)
                          for f in copies.split(',') if f]

            try:
                templates = config.get(section, 'template')
            except ConfigParser.NoOptionError:
                templates = ''

            if templates == '*':
                templates = glob.glob(os.path.join(sectiondir, '*'))
                templates.extend(glob.glob(os.path.join(sectiondir, '.*')))
            else:
                templates = \
                    [os.path.join(sectiondir, f)
                     for f in templates.split(',') if f]

            for link in links:
                if not (link.endswith('dotfile.pre_install')
                        or link.endswith('dotfile.post_install')):
                    if len(link.split('->')) == 2:
                        link, dst = link.split('->')
                    else:
                        dst = link
                    dst = dst.lstrip(sectiondir).lstrip('/')
                    dst = os.path.expanduser(os.path.join('~', dst))
                    _install_file('link', link, dst)

            for copy in copies:
                if not (copy.endswith('dotfile.pre_install')
                        or copy.endswith('dotfile.post_install')):
                    if len(copy.split('->')) == 2:
                        copy, dst = copy.split('->')
                    else:
                        dst = copy
                    dst = dst.lstrip(sectiondir).lstrip('/')
                    dst = os.path.expanduser(os.path.join('~', dst))
                    _install_file('copy', copy, dst)

            for template in templates:
                if not (template.endswith('dotfile.pre_install')
                        or template.endswith('dotfile.post_install')):
                    try:
                        context_vars = config.get(section, 'template_context')
                    except ConfigParser.NoOptionError:
                        context_vars = ''
                    context_vars = [x for x in context_vars.split(',') if x]
                    dst = template.lstrip(sectiondir).lstrip('/')
                    dst = os.path.expanduser(os.path.join('~', dst))
                    _install_file('template', template, dst, context_vars)

            post_install = os.path.join(sectiondir, 'dotfile.post_install')
            if os.path.exists(post_install) \
                    and os.access(post_install, os.X_OK):
                local(post_install)
        elif stype == 'installer':
            try:
                installs = [x.strip() for x in
                            config.get(section, 'install').split(',')
                            if x.strip()]
            except ConfigParser.NoOptionError:
                installs = []

            try:
                cargs = config.get(section, 'args')
            except ConfigParser.NoOptionError:
                cargs = ''

            try:
                upgrade_args = config.get(section, 'upgrade_args')
            except ConfigParser.NoOptionError:
                upgrade_args = cargs

            try:
                sudo = config.getboolean(section, 'sudo')
            except ConfigParser.NoOptionError:
                sudo = False
            try:
                multi = config.getboolean(section, 'multiple_install')
            except ConfigParser.NoOptionError:
                multi = False
            if upgrade and upgrade_args:
                cargs = upgrade_args
            if multi:
                install = ' '.join(installs)
                command = '{0} {1} {2}'.format(section_name, cargs, install)
                if sudo:
                    command = 'sudo {0}'.format(command)
                with settings(warn_only=True):
                    local(command)
            else:
                for install in installs:
                    command = '{0} {1} {2}'\
                              .format(section_name, cargs, install)
                    if sudo:
                        command = 'sudo {0}'.format(command)
                    with settings(warn_only=True):
                        local(command)

        elif stype == 'script':
            script = os.path.join(
                os.path.join(os.path.dirname(__file__), 'scripts'),
                section_name
            )
            if not (os.path.exists(script) and os.access(script, os.X_OK)):
                logging.error('"{0}" is not a valid script.'.format(script))
                sys.exit(1)
            try:
                sudo = config.getboolean(section, 'sudo')
            except ConfigParser.NoOptionError:
                sudo = False
            try:
                cwd = config.get(section, 'cwd')
            except ConfigParser.NoOptionError:
                cwd = ''
            with lcd(os.path.join(
                    os.path.dirname(__file__), os.path.expanduser(cwd))):
                if sudo:
                    local('sudo {0}'.format(script))
                else:
                    local(script)
        else:
            logging.error('{0}? WTF am I meant to do with that?'
                          .format(section))
            sys.exit(1)
        logging.info('Installed {0}...'.format(section))


@task
def update_submodules():
    '''
    Update all git submodules in tree.
    '''
    local('git submodule update --init')
    local('git submodule foreach --recursive "git checkout master"')
    local('git submodule foreach --recursive "git pull"')


@task
def add_git_dude_repo(repo, method='clone'):
    if not method in ['clone', 'link']:
        logging.error('{0} is not a valid method!'.format(method))
        return
    if not os.path.isdir(os.path.expanduser('~/.git-dude')):
        try:
            os.makedirs(os.path.expanduser('~/.git-dude'))
        except OSError as e:
            logging.error(
                'Error creating ~/.git-dude directory: {0}'.format(e)
            )
            return
    with lcd(os.path.expanduser('~/.git-dude')):
        if method == 'clone':
            local('git clone --mirror "{0}"'.format(repo))
        elif method == 'link':
            repo = os.path.abspath(os.path.expanduser(repo))
            local('ln -s "{0}"'.format(repo))


@task
def switch_ssh_config(config=None):
    SSH_CONFIG = os.path.expanduser('~/.ssh/config')
    if config is not None:
        config = os.path.expanduser(os.path.join('~/.ssh/configs/', config))
    else:
        configs = sorted(glob.glob(os.path.expanduser('~/.ssh/configs/*')))
        menu = dict(enumerate(configs))
        selection = None
        while config is None:
            try:
                print('Select a config to enable:')
                for i, conf in menu.items():
                    print('    {0}: {1}'.format(i, os.path.basename(conf)))
                try:
                    selection = int(raw_input())
                except ValueError:
                    selection = None
                if selection in menu:
                    config = menu[selection]
            except KeyboardInterrupt:
                logging.info('Aborted...')
                return
    if not os.path.exists(config):
        logging.error(
            'SSH config "{0}" does not exist in ~/.ssh/configs/'.format(
                config
            )
        )
        return
    if os.path.exists(SSH_CONFIG) or os.path.islink(SSH_CONFIG):
        os.remove(SSH_CONFIG)
    os.symlink(config, SSH_CONFIG)
    logging.info('Linked "{0}" to "{1}".'.format(SSH_CONFIG, config))
