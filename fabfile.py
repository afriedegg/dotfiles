import ConfigParser
import glob
import os
import shutil
import logging

import jinja2
from fabric.api import local


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
           answer = raw_input('Got %s. Is this correct? [Yn]\t' % context[var])
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


def _make_link(src, dst):
    backup = False
    if os.path.exists(dst):
        action = raw_input('%s exists? [B]ackup [o]verwrite ' \
                           '[c]ancel [a]bort\t' % dst)
        if action.lower().startswith('o'):
            logging.info('Overwriting %s with link to %s.' % (dst, src))
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
    try:
        logging.info('Linking %s %s' % (src.rstrip('/'), dst.rstrip('/')))
        os.symlink(src.rstrip('/'), dst.rstrip('/'))
    except:
        if not backup:
            logging.error('Failed to link %s' % src)
        else:
            logging.info('Failed to link %s, attempting to restore ' \
                         'from backup...' % src)
            try:
                os.rename(backup, dst)
                logging.info('Restored')
            except:
                logging.error('Failed to restore backup %s. Aborting...' \
                              % backup)
                exit(1)



def _make_copy(src, dst):
    backup = False
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
    try:
        shutil.copy2(src, dst)
    except:
        if not backup:
            logging.error('Failed to copy %s' % src)
        else:
            logging.info('Failed to copy %s, attempting to restore ' \
                         'from backup...' % src)
            try:
                os.rename(backup, dst)
                logging.info('Restored')
            except:
                logging.error('Failed to restore backup %s. ' \
                              'Aborting...' % backup)
                exit(1)


def _save_template(src, dst, context):
    backup = False
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
    if isinstance(context, basestring):
        context = context.split(',')
    context = _get_template_context(*context)
    content = _render_template(src, context)
    try:
        with open(dst, 'w') as f:
            f.write(content)
    except:
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


def install():
    basedir = os.path.dirname(__file__)
    config = ConfigParser.ConfigParser()
    config.read(os.path.join(basedir, 'dotfiles.conf'))

    for section in config.sections():
        install = raw_input('Install %s? [Yn]\t' % section)
        if install and not install.lower().startswith('y'):
            continue
        sectiondir = os.path.join(basedir, section).rstrip('/')
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
                _make_link(link, dst)

        for copy in copies:
            if not (copy.endswith('dotfile.preinstall') \
                    or copy.endswith('dotfile.postinstall')):
                dst = copy.lstrip(sectiondir).lstrip('/')
                dst = os.path.expanduser(os.path.join('~', dst))
                _make_copy(copy, dst)
                logging.info('Copying %s to %s' % (copy, dst))

        for template in templates:
            if not (link.endswith('dotfile.preinstall') \
                    or link.endswith('dotfile.postinstall')):
                try:
                    context_vars = config.get(section, 'template_context')
                except ConfigParser.NoOptionError:
                    context_vars = ''
                context_vars = [x for x in context_vars.split(',') if x]
                dst = template.lstrip(sectiondir).lstrip('/')
                dst = os.path.expanduser(os.path.join('~', dst))
                _save_template(template, dst, context_vars)

        postinstall = os.path.join(sectiondir, 'dotfile.postinstall')
        if os.path.exists(postinstall) and os.access(postinstall, os.X_OK):
            local(postinstall)
        logging.info('Installed %s...' % section)
