# JollaCNAPI

## 准备 ##

创建对应postgres用户

```bash
sudo -u postgres createuser --superuser jollacn_api
sudo -u postgres psql -c '\password jollacn_api'
 export PGPASSWORD="jollacn_api"
psql -W --no-password -h 127.0.0.1 -U jollacn_api template1 -c 'CREATE DATABASE jollacn_api'
# psql -W --no-password -h 127.0.0.1 -U fuse_api fuse_api -c 'CREATE EXTENSION IF NOT EXISTS "uuid-ossp"'
export PGPASSWORD=''
```

## 发布流程 ##

```bash
# release.init  # for first time
# build: cd ~/source/jollacn_api
export version="$(cat mix.exs | grep version | awk '{print substr($2, 2, length($2)-3)}')"
echo "version=${version}"
MIX_ENV=prod mix release --env=prod
cp _build/prod/rel/jollacn_api/releases/${version}/jollacn_api.tar.gz ~/release/jollacn_api
mkdir ~/release/jollacn_api/template
rsync -r --progress lib/jollacn/template ~/release/jollacn_api

# release: cd ~/release/jollacn_api
tar -xzf jollacn_api.tar.gz

# run(acutally under supervisor)
bin/jollacn_api foreground

# upgrade: cd ~/source/jollacn_api
export version="$(cat mix.exs | grep version | awk '{print substr($2, 2, length($2)-3)}')"
echo "version=${version}"
MIX_ENV=prod mix release --upgrade --env=prod
mkdir -p ~/release/jollacn_api/releases/${version} && cp _build/prod/rel/jollacn_api/releases/${version}/jollacn_api.tar.gz ~/release/jollacn_api/releases/${version}/jollacn_api.tar.gz
mkdir ~/release/jollacn_api/template
rsync -r --progress lib/jollacn_api/template ~/release/jollacn_api

# do upgrade: cd ~/release/jollacn_api
bin/jollacn_api upgrade "${version}"
```
