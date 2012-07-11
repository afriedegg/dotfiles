import ConfigParser
import glob
import os
import shutil
import logging
import re

import jinja2
from fabric.api import local, lcd


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
            context[var] = raw_input('Enter %s :\t' % var)
            answer = raw_input('Got %s. Is this correct? [Yn]\t' \
                                % context[var])
            if not answer or answer.lower().startswith('y'):
                confirmed = True
    return context


def _create_backup(dst):
    if os.path.exists(dst):
        backup = backup_orig = '%s.backup' % dst.rstrip('/')
        logging.info('Creating backup of %s at %s' % (dst, backup))

        i = 1
        while os.path.exists(backup):
            backup = '%s.%s' % (backup_orig, i)
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
        action = raw_input('%s exists? [B]ackup [o]verwrite ' \
                           '[c]ancel [a]bort\t' % dst)
        if action.lower().startswith('o'):
            logging.info('Overwriting %s with %s.' % (dst, src))
            try:
                os.remove(dst.rstrip('/'))
            except:
                os.rmdir(dst.rstrip('/'))
        elif action.lower().startswith('c'):
            logging.info('Not installing %s.' % src)
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
            logging.debug('Writing template to %s' % dst)
            with open(dst, 'w') as f:
                f.write(content)
        except:
            failure = True
    elif method == 'link':
        try:
            logging.debug('Linking %s to %s' \
                            % (src.rstrip('/'), dst.rstrip('/')))
            os.symlink(src.rstrip('/'), dst.rstrip('/'))
        except:
            failure = True
    elif method == 'copy':
        try:
            logging.debug('Copying %s to %s' \
                            % (src.rstrip('/'), dst.rstrip('/')))
            shutil.copy2(src, dst)
        except:
            failure = True
    else:
        logging.info('%(a)s? %(a)s? WTF is %(a)s?' % {'a': method})
    if failure:
        if not backup:
            logging.error('Failed to write %s' % src)
        else:
            logging.info('Failed to write %s, attempting to restore ' \
                         'from backup...' % src)
            try:
                os.rename(backup, dst)
                logging.info('Restored')
            except:
                logging.error('Failed to restore backup %s. ' \
                              'Aborting...' % backup)
                exit(1)


def install(section=None):
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

        install = raw_input('Install %s? [Yn]\t' % section_name)
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
                args = config.get(section, 'args')
            except ConfigParser.NoOptionError:
                args = ''

            try:
                sudo = config.getboolean(section, 'sudo')
            except ConfigParser.NoOptionError:
                sudo = False
            for install in installs:
                command = '%s %s %s' % (section_name, args, install)
                if sudo:
                    command = 'sudo %s' % command
                local(command)
        else:
            logging.error('%s? WTF am I meant to do with that?' % section)
        logging.info('Installed %s...' % section)


def update_submodules():
    local('git submodule init')
    local('git submodule foreach --recursive '\
          '"(git checkout master; git pull)&"')
    local('git submodule update --recursive')
    local('git submodule status --recursive')
    local('git submodule')


def make_command_t(update=False):
    if update:
        local('git submodule update --recursive vim/.vim/bundle/command-t/')
    with lcd('vim/.vim/bundle/command-t/ruby/command-t/'):
        local('ruby extconf.rb')
        local('make && rake make')
