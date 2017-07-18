#!/usr/bin/env bash

#if brew ls --versions openssl > /dev/null; then
#    echo "Detected $OS..."
#    echo "Setting needed ENV to build psycopg2..."
#    export LDFLAGS="-L/usr/local/opt/openssl/lib"
#    export CPPFLAGS="-I/usr/local/opt/openssl/include"
#    export PKG_CONFIG_PATH="/usr/local/opt/openssl/lib/pkgconfig"
#fi

#######################
#  Dependency Checks  #
#######################

# Function to check if referenced command exists
cmd_exists() {
  if [ $# -eq 0 ]; then
    echo 'WARNING: No command argument was passed to verify exists'
  fi

  #cmds=($(echo "${1}"))
  cmds=($(printf '%s' "${1}"))
  fail_counter=0
  for cmd in "${cmds[@]}"; do
    command -v "${cmd}" >&/dev/null # portable 'which'
    rc=$?
    if [ "${rc}" != "0" ]; then
      fail_counter=$((fail_counter+1))
    fi
  done

  if [ "${fail_counter}" -ge "${#cmds[@]}" ]; then
    echo "Unable to find one of the required commands [${cmds[*]}] in your PATH"
    return 1
  fi
}

pip_cmd_list=('pip')
for cmd in "${pip_cmd_list[@]}"; do
  cmd_exists "${cmd[@]}"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo "Installing Python PIP via Easy_Install"
    sudo easy_install pip
  fi
done

virtenv_cmd_list=(
  'virtualenv virtualenv-2.7 virtualenv-2.5'
)
for cmd in "${virtenv_cmd_list[@]}"; do
  cmd_exists "${cmd[@]}"
  # shellcheck disable=SC2181
  if [ $? -ne 0 ]; then
    echo "Installing Python virtualenv via PIP"
    sudo pip install virtualenv
  fi
done

# Check to see if the xcode commandline tools are installed
# This will prompt the users to install if required
if ! xcode-select -p >&/dev/null; then
  echo 'Installing XCODE'
  touch /tmp/.com.apple.dt.CommandLineTools.installondemand.in-progress;
  PROD=$(softwareupdate -l |
    grep "\*.*Command Line" |
    grep "$(sw_vers -productVersion)" |
    awk -F"*" '{print $2}' |
    sed -e 's/^ *//' |
    tr -d '\n')
  softwareupdate -i "$PROD";
fi

#######################
#  Library Functions  #
#######################

run() {
    "$@"
    rc=$?
    if [[ $rc -gt 0 ]]; then
        return $rc
    fi
}

#######################
echo " -------------------------------------------------------------------"
echo "|                                                                   |"
echo "| You should be running this with "source ./setup.sh"               |"
echo "| Running this directly like:                                       |"
echo "| * ./setup.sh                                                      |"
echo "| * bash ./setup.sh                                                 |"
echo "| Will fail to set certain environment variables that may bite you. |"
echo "|                                                                   |"
echo "|                                                                   |"
echo "| Waiting 5 seconds for you make sure you have ran this correctly   |"
echo "| Cntrl-C to bail out...                                            |"
echo "|                                                                   |"
echo " -------------------------------------------------------------------"

for n in {5..1}; do
  printf "\r%s " $n
  sleep 1
done

if [ ! -d ./.venv ]; then
    echo "Failed to find a virtualenv, creating one."
    run virtualenv ./.venv
else
    echo "Found existing virtualenv, using that instead."
fi

. ./.venv/bin/activate
run pip install --upgrade pip
run pip install --upgrade setuptools
run pip install -r requirements.txt
run ansible-galaxy install -r requirements.yml -p galaxy_roles -f

echo " ----------------------------------------------------------------------------"
echo "|                                                                            |"
echo "| You are now within a python virtualenv at ./.venv                          |"
echo "| This means that all python packages installed will not affect your system. |"
echo "| To return _back_ to system python, run deactivate in your shell.           |"
echo "|                                                                            |"
echo " ----------------------------------------------------------------------------"
