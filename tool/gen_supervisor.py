"""
Usage:
    python supervisor.py | sudo tee /etc/supervisor/conf.d/jollacn_api.conf
"""
import sys
import os.path
import getpass
from string import Template

project_path = os.path.normpath(os.path.abspath(os.path.join(__file__, '..', '..')))
dir_name = os.path.split(project_path)[-1]

template = """[program:jollacn_api]
command=${PROJECT_PATH}/release/bin/jollacn_api foreground
directory=${PROJECT_PATH}/release
environment=HOME="${HOME}",USER="${USER}",MIX_ENV=prod
autostart=true
autorestart=true
user=${USER}
stdout_logfile=/var/log/supervisor/jollacn_api-stdout.log
stderr_logfile=/var/log/supervisor/jollacn_api-stderr.log
stdout_logfile_maxbytes=0
stderr_logfile_maxbytes=0
stdout_logfile_backups=0
stderr_logfile_backups=0
stopasgroup=true
killasgroup=true"""

home_path = os.path.expanduser('~')
user = getpass.getuser()

config = Template(template).safe_substitute({
    'PROJECT_PATH': project_path,
    'HOME': home_path,
    'USER': user,
    # 'DIRNAME': dir_name,
})

print(config)

sys.stderr.write(__doc__)
