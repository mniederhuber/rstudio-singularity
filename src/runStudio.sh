#!/bin/bash
#SBATCH -p interact
#SBATCH --time=8:00:00
#SBATCH --signal=USR2
#SBATCH --ntasks=1
#SBATCH -o var/logs/studio-%j.out
#SBATCH -e var/logs/studio-%j.err

#TODO make this a parameter that can be set in a separate config file
copy_prefs=false

module purge
module load singularity

export TMPDIR="${PWD}"

#####
## export variables and make directories
#####

# make directories
mkdir -p "$TMPDIR/tmp/${SLURM_JOB_ID}/rstudio-server"
uuidgen > "$TMPDIR/tmp/${SLURM_JOB_ID}/rstudio-server/secure-cookie-key"
chmod 0600 "$TMPDIR/tmp/${SLURM_JOB_ID}/rstudio-server/secure-cookie-key"

mkdir -p "$TMPDIR/var/lib"
mkdir -p "$TMPDIR/var/run"
mkdir -p "$TMPDIR/.config"
mkdir -p "$TMPDIR/.local/share"
# copy the user global options to the project direcotry .config


if $copy_prefs; then
  cp $TMPDIR/rstudio-singularity/conf/rstudio-prefs.json $TMPDIR/.config/rstudio/.
fi
cp $TMPDIR/rstudio-singularity/conf/auth $TMPDIR/.config/.

## export variables
# set the working directory

if [ ! -d "$TMPDIR"/var/logs ];then
	mkdir -p "$TMPDIR"/var/logs
fi
# PAM auth helper used by RStudio
export RSTUDIO_AUTH="${TMPDIR}/.config/auth"


# https://github.com/DOI-USGS/lake-temperature-model-prep/blob/47db0d8a4b276ee3514132aaedec1d32776f7558/launch-rstudio-container.slurm#L18
# Set the local directory as the place for session information. This should make
# command line history more relevant, as it will be restricted to the project
# currently being worked on.
# Based on:
# Pointer here: https://support.rstudio.com/hc/en-us/articles/218730228-Resetting-a-user-s-state-on-RStudio-Workbench-RStudio-Server
# RStudio Workbench admin guide here: https://docs.rstudio.com/ide/server-pro/r_sessions/customizing_session_settings.html
# XDG Base Directory Specification here: https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
export SINGULARITYENV_XDG_DATA_HOME=${TMPDIR}/.local/share
export SINGULARITYENV_XDG_CONFIG_HOME=${TMPDIR}/.config/rstudio

### make rsession.conf
# sets the current working directory as the default starting point for the rstudio session
# also, sets a library path to within the sandboxed image, to allow for additional package installation
# the user home directory should be bound by default 
cat > "$TMPDIR/.config/rsession.conf" << EOF 
session-save-action-default=no
session-default-working-dir=${TMPDIR} 
EOF

# from UNC ondemand rstudio server setup scripts:
# Generate a database.conf file
export DBCONF="${TMPDIR}/.config/database.conf"
(
umask 077
sed 's/^ \{2\}//' > "${DBCONF}" << EOL
  # set database location
  provider=sqlite
  directory=${TMPDIR}/tmp/${SLURM_JOB_ID}/rstudio-server/db
EOL
)
chmod 700 "${DBCONF}"

#####
## get sif file, export password, and assign avail port 
#####

sifFile=$1

export PASSWORD=$(openssl rand -base64 8)

# get unused socket per https://unix.stackexchange.com/a/132524
# tiny race condition between the python & singularity commands
readonly PORT=$(python -c 'import socket; s=socket.socket(); s.bind(("", 0)); print(s.getsockname()[1]); s.close()')


#####
# write out instructions
#####

cat > rstudio-login.txt <<END

Rstudio server started with working directory: ${TMPDIR}

1. SSH tunnel from your workstation using the following command:

ssh -N -L 8989:${HOSTNAME}:${PORT} ${USER}@longleaf.unc.edu

and point your web browser to http://localhost:8989

2. log in to RStudio Server using the following credentials:

username: <YOUR LL USERNAME>
pass: ${PASSWORD}

To end the session:
Press red power button in the RStudio Server web interface to log out.
*I believe this is important to properly close any lingering processes.*

Then:
scancel -f ${SLURM_JOB_ID}
END

##################
## START SERVER ##
##################

# Also bind data directory on the host into the Singularity container.
# By default the only host file systems mounted within the container are $HOME, /tmp, /proc, /sys, and /dev.
##NOTE##
# You may need here just to replace the fourth bind option, or drop

RSTUDIO_PASSWORD=${PASSWORD} singularity exec \
  --bind="$TMPDIR/var/lib:/var/lib/rs${SLURM_JOB_ID}tudio-server" \
  --bind="$TMPDIR/var/run:/var/run/rstudio-server" \
  --bind="$TMPDIR/tmp/${SLURM_JOB_ID}:/tmp" \
  --bind="$TMPDIR/.config/rsession.conf:/etc/rstudio/rsession.conf" \
  --bind="$TMPDIR:$TMPDIR" \
  $sifFile \
  rserver --server-user ${USER} \
    --www-port ${PORT} \
    --auth-none=0 \
    --auth-pam-helper-path "$TMPDIR/.config/auth" \
    --database-config-file "${DBCONF}" \
    --auth-timeout-minutes=0 --auth-stay-signed-in-days=2 
printf 'rserver exited' 1>&2
