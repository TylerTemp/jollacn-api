set -e;
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )";
PROJECTPATH=$(dirname ${SCRIPTPATH});
# PROJECTDIRNAME=$(basename ${PROJECTPATH});

echo  $PROJECTPATH;
# echo  $PROJECTDIRNAME;

cd $PROJECTPATH;

MIX_ENV=prod mix deps.get;

if [ -f "rel/config.exs" ]; then
  echo "release config already exists";
else
  echo "creating release config";
  MIX_ENV=prod mix distillery.init;
fi;

export version="$(cat mix.exs | grep version | awk '{print substr($2, 2, length($2)-3)}')";
echo "version=${version}";

export appname="$(cat mix.exs | grep 'app:' | awk '{print substr($2, 2, length($2)-2)}')";
echo "appname=${appname}";

MIX_ENV=prod mix distillery.release --verbose;
mkdir -p "${PROJECTPATH}/release";
cp "_build/prod/rel/${appname}/releases/${version}/${appname}.tar.gz" "${PROJECTPATH}/release";
cd "${PROJECTPATH}/release";
tar -xvzf "${appname}.tar.gz";

sudo supervisorctl reread;
sudo supervisorctl update;
sudo supervisorctl start "$1";
