import tempfile
import os
import requests


def get_file():
    return os.path.join(tempfile.gettempdir(), 'jollacn_jwt.txt')


def login(name, password, host=None):
    if host is None:
        host = 'https://notexists.top/api'
    if not host.startswith('http'):
        host = 'http://' + host
    url = host + '/user/login'
    args = {
        'name': name,
        'password': password,
    }

    resp = requests.post(url, json=args)
    print(resp.status_code)
    print(resp.json())
    token = resp.json()['jwt_token']
    with open(get_file(), 'w', encoding='utf-8') as f:
        f.write(token)
    return token

def get_token(name, password, host=None):
    temp_file = get_file()
    try:
        with open(temp_file, 'r', encoding='utf-8') as f:
            return f.read().strip()
    except BaseException as _:
        return login(name, password, host)



class LoginReq(object):

    def __init__(self, name, password, host=None):
        self.name = name
        self.password = password
        self.host = host
        self.login()

    def login(self):
        self.token = login(self.name, self.password, self.host)

    def post(self, *args, **kwargs):
        return self.call_method('post', *args, **kwargs)

    def get(self, *args, **kwargs):
        return self.call_method('get', *args, **kwargs)

    def patch(self, *args, **kwargs):
        return self.call_method('patch', *args, **kwargs)

    def put(self, *args, **kwargs):
        return self.call_method('put', *args, **kwargs)

    def call_method(self, method, *args, **kwargs):
        headers = kwargs.pop('headers', {})
        headers['Authorization'] = 'Bearer {}'.format(self.token)
        kwargs['headers'] = headers
        resp = requests.request(method, *args, **kwargs)
        if resp.status_code == 401 and resp.json()['message'].startswith('token expired'):
            self.login()
        return requests.request(method, *args, **kwargs)

if __name__ == '__main__':
    import sys
    # _, name, password = sys.argv
    name = sys.argv[1]
    password = sys.argv[2]
    if len(sys.argv) > 3:
        host = sys.argv[3]
    else:
        host = None
    print(get_token(name, password, host))
