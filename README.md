# Rstudio + Singularity Template


> GOAL \
> To set up a relatively simple, reproducible, and trackable workflow for running R/Rstudio from the UNC longleaf HPC, using a combination of singularity/apptainer containerization, and renv.

>[!NOTE] \
> this template is designed specifically for the UNC HPC, but could be a general guide for running rstudio-server within a container from a remote HPC. 

# instructions

1. clone this repository into a new project directory on HPC, best location is `/work/` \
```bash
git clone git@github.com:mniederhuber/rstudio-singularity.git
```

2. build the singularity image - assumes installation of apptainer 
needs to be run in an interactive session...
```bash
module load apptainer
apptainer build defFile/bio_dev.sif bio_dev.def
```
3. start up rstudio server \
This script does a few things... \
It makes some temporary directors for server stuff, \
writes a brief `rsession.conf` file with a couple paths to define default working directory \
and a `r-libs-user` path for writing new packages ==which is only relevant if image is built as sandbox== \
It then binds some paths to the container and executes rstudio server with the container. 

```bash
sbatch scripts/runStudio.sh
```

3. start a tunnel from your local machine \
check the slurm out file for deets. #TODO make this more accessible, print to stdout?

```bash
ssh -N -L 8989:${remote.HOSTNAME}:${remote.PORT} ${USER}@longleaf.unc.edu
```

4. open rstudio in browser at `http://localhost:8989` and enter credentials

5. `renv` is included in the container installation and can then be used to track package versions \
There may be a better way to do this, but the current set up pulls a `rocker/tidyverse:4.3.2` \
which I believe pulls latest versions of a series of included packages... but these may have explict versions defined... 


# notes

- use bioconductor image as base and extend as needed
	- needs rstudio and rstudio server
	- needs magrittr, dplyr, other tidyverse, ggplot2o

bioconductor_docker image has `rocker/rstudio` as base image
https://github.com/Bioconductor/bioconductor_docker


