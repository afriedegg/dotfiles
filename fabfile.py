import ConfigParser
import glob
import os
import shutil
import logging
import re

import jinja2
from fabric.api import lcd, local, settings, task


logging.basicConfig(level=logging.INFO)


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
            answer = raw_input('Got {0}. Is this correct? [Yn]\t'\
                                .format(context[var]))
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
    if os.path.exists(dst):
        action = raw_input('{0} exists? [B]ackup [o]verwrite ' \
                           '[c]ancel [a]bort\t'.format(dst))
        if action.lower().startswith('o'):
            logging.info('Overwriting {0} with {1}.'.format(dst, src))
            try:
                os.remove(dst.rstrip('/'))
            except:
                os.rmdir(dst.rstrip('/'))
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
            logging.debug('Linking {0} to {1}'\
                          .format(src.rstrip('/'), dst.rstrip('/')))
            os.symlink(src.rstrip('/'), dst.rstrip('/'))
        except:
            failure = True
    elif method == 'copy':
        try:
            logging.debug('Copying {0} to {1}'\
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
            logging.info('Failed to write {0}, attempting to restore ' \
                         'from backup...'.format(src))
            try:
                os.rename(backup, dst)
                logging.info('Restored')
            except:
                logging.error('Failed to restore backup {0}. ' \
                              'Aborting...'.format(backup))
                exit(1)

@task
def install(section=None, *args, **kwargs):
    '''
    Install dotfile sections.

    Optionally pass in the name of a section to only install that section.
    '''
    update_submodules()

    basedir = os.path.dirname(__file__)
    config = ConfigParser.ConfigParser()
    config.read(os.path.join(basedir, 'dotfiles.conf'))

    sections = []
    if section is not None:
        for s in re.split('[\s,]+', section):
            if s in config.sections():
                sections.append(s)
            else:
                found = False
                for type in ['files', 'installer']:
                    if ':'.join([type, s]) in config.sections():
                        sections.append(':'.join([type, s]))
                        found = True
                        break
                if not found:
                    raise Exception('Could not find section {0}'.format(s))
    else:
        sections = config.sections()

    for section in sections:
        if ':' in section:
            stype, section_name = section.split(':')
        else:
            stype, section_name = 'file', section

        install = raw_input('Install {0}? [Yn]\t'.format(section_name))
        if install and not install.lower().startswith('y'):
            continue
        if stype == 'files':
            sectiondir = os.path.join(basedir, section_name).rstrip('/')
            preinstall = os.path.join(sectiondir, 'dotfile.preinstall')
            if os.path.exists(preinstall) and os.access(preinstall, os.X_OK):
                local(preinstall)

            try:
                links = config.get(section, 'link')
            except ConfigParser.NoOptionError:
                links = ''

            if links == '*':
                links = glob.glob(os.path.join(sectiondir, '*'))
                links.extend(glob.glob(os.path.join(sectiondir, '.*')))
            else:
                links = [os.path.join(sectiondir, f) \
                         for f in links.split(',') if f]

            try:
                copies = config.get(section, 'copy')
            except ConfigParser.NoOptionError:
                copies = ''

            if copies == '*':
                copies = glob.glob(os.path.join(sectiondir, '*'))
                copies.extend(glob.glob(os.path.join(sectiondir, '.*')))
            else:
                copies = [os.path.join(sectiondir, f) \
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
                        [os.path.join(sectiondir, f) \
                         for f in templates.split(',') if f]

            for link in links:
                if not (link.endswith('dotfile.preinstall') \
                        or link.endswith('dotfile.postinstall')):
                    dst = link.lstrip(sectiondir).lstrip('/')
                    dst = os.path.expanduser(os.path.join('~', dst))
                    _install_file('link', link, dst)

            for copy in copies:
                if not (copy.endswith('dotfile.preinstall') \
                        or copy.endswith('dotfile.postinstall')):
                    dst = copy.lstrip(sectiondir).lstrip('/')
                    dst = os.path.expanduser(os.path.join('~', dst))
                    _install_file('copy', copy, dst)

            for template in templates:
                if not (template.endswith('dotfile.preinstall') \
                        or template.endswith('dotfile.postinstall')):
                    try:
                        context_vars = config.get(section, 'template_context')
                    except ConfigParser.NoOptionError:
                        context_vars = ''
                    context_vars = [x for x in context_vars.split(',') if x]
                    dst = template.lstrip(sectiondir).lstrip('/')
                    dst = os.path.expanduser(os.path.join('~', dst))
                    _install_file('template', template, dst, context_vars)

            postinstall = os.path.join(sectiondir, 'dotfile.postinstall')
            if os.path.exists(postinstall) and os.access(postinstall, os.X_OK):
                local(postinstall)
        elif stype == 'installer':
            try:
                installs = [x.strip() for x in \
                            config.get(section, 'install').split(',') \
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
                upgrade_args = ''

            try:
                sudo = config.getboolean(section, 'sudo')
            except ConfigParser.NoOptionError:
                sudo = False
            for install in installs:

                if 'upgrade' in args and upgrade_args:
                    cargs = upgrade_args
                command = '{0} {1} {2}'.format(section_name, cargs, install)
                if sudo:
                    command = 'sudo {0}'.format(command)
                with settings(warn_only=True):
                    local(command)

        else:
            logging.error('{0}? WTF am I meant to do with that?'\
                          .format(section))
        logging.info('Installed {0}...'.format(section))

@task
def update_submodules():
    '''
    Update all git submodules in tree.
    '''
    local('git submodule init')
    local('git submodule foreach --recursive '\
          '"(git checkout master; git pull)&"')
    local('git submodule update --recursive')
    local('git submodule status --recursive')
    local('git submodule')

@task
def make_command_t(update=False):
    '''
    Builds the command_t vim extension.

    Takes an optional update argument which, if given, will perform an
    update of the command-t source tree before building.
    '''
    if update:
        local('git submodule update --recursive vim/.vim/bundle/command-t/')
    with lcd('vim/.vim/bundle/command-t/ruby/command-t/'):
        local('ruby extconf.rb')
        local('make && rake make')
