set -e;
SCRIPTPATH="$( cd "$(dirname "$0")" ; pwd -P )";
PROJECTPATH=$(dirname ${SCRIPTPATH});
# PROJECTDIRNAME=$(basename ${PROJECTPATH});

echo $PROJECTPATH;
# echo $PROJECTDIRNAME;

cd $PROJECTPATH;

MIX_ENV=prod mix deps.get;

export version="$(cat mix.exs | grep version | awk '{print substr($2, 2, length($2)-3)}')";
echo "version=${version}";

export appname="$(cat mix.exs | grep 'app:' | awk '{print substr($2, 2, length($2)-2)}')";
echo "appname=${appname}";

MIX_ENV=prod mix distillery.release --upgrade --verbose;
mkdir -p "${PROJECTPATH}/release/releases/${version}";
cp "_build/prod/rel/${appname}/releases/${version}/${appname}.tar.gz" "${PROJECTPATH}/release/releases/${version}/${appname}.tar.gz";

# do upgrade
MIX_ENV=prod mix ecto.migrate;
cd "${PROJECTPATH}/release";
"bin/${appname}" upgrade "${version}";
