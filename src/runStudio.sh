#!/bin/bash
#SBATCH -p interact
#SBATCH --time=8:00:00
#SBATCH --signal=USR2
#SBATCH --ntasks=1
#SBATCH -o var/logs/studio-%j.out
#SBATCH -e var/logs/studio-%j.err


module purge
module load singularity

#####
## export variables and make directories
#####

# set the working directory
export TMPDIR="${PWD}"

if [ ! -d "$TMPDIR"/var/logs ];then
	mkdir -p "$TMPDIR"/var/logs
fi

# necessary?
export LANG="en_US.UTF-8"
export LC_COLLATE="en_US.UTF-8"
export LC_CTYPE="en_US.UTF-8"
export LC_MESSAGES="en_US.UTF-8"
export LC_MONETARY="en_US.UTF-8"
export LC_NUMERIC="en_US.UTF-8"
export LC_TIME="en_US.UTF-8"
export LC_ALL="en_US.UTF-8"

mkdir -p "$TMPDIR/tmp/rstudio-server"
uuidgen > "$TMPDIR/tmp/rstudio-server/secure-cookie-key"
chmod 0600 "$TMPDIR/tmp/rstudio-server/secure-cookie-key"

mkdir -p "$TMPDIR/var/lib"
mkdir -p "$TMPDIR/var/run"
mkdir -p "$TMPDIR/conf"

### make rsession.conf
# sets the current working directory as the default starting point for the rstudio session
# also, sets a library path to within the sandboxed image, to allow for additional package installation
# the user home directory should be bound by default 
cat > "$TMPDIR/conf/rsession.conf" << EOF 
session-default-working-dir=${TMPDIR} 
EOF

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

cat <<END

1. SSH tunnel from your workstation using the following command:

ssh -N -L 8989:${HOSTNAME}:${PORT} ${USER}@longleaf.unc.edu

and point your web browser to http://localhost:8989

> [!NOTE] 
> The port 8989 is arbitrary. 
> It just needs to be any open port on your local machine.

2. log in to RStudio Server using the following credentials:

username: <YOUR LL USERNAME>
pass: ${PASSWORD}


When done using RStudio Server, terminate the job by:

1. Exit the RStudio Session ("power" button in the top right corner of the RStudio window)
2. Issue the following command on the login node:

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
  --bind="$TMPDIR/var/lib:/var/lib/rstudio-server" \
  --bind="$TMPDIR/var/run:/var/run/rstudio-server" \
  --bind="$TMPDIR/tmp:/tmp" \
  --bind="$TMPDIR/conf/rsession.conf:/etc/rstudio/rsession.conf" \
  --bind="$TMPDIR:$TMPDIR" \
  $sifFile \
  rserver --server-user ${USER} \
    --www-port ${PORT} \
    --auth-none=0 \
    --auth-pam-helper-path "$TMPDIR/conf/auth" \
    --auth-timeout-minutes=0 --auth-stay-signed-in-days=30 
printf 'rserver exited' 1>&2
