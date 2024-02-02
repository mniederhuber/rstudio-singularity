# Rstudio + Singularity Template


> GOAL
> To set up a relatively simple, reproducible, and trackable workflow for running R/Rstudio from the UNC longleaf HPC, using a combination of singularity/apptainer containerization, and renv.

> **NOTE** 
> This template is designed specifically for the UNC HPC, but could be a general guide for running rstudio-server within a container from a remote HPC. 

# Instructions

1. clone this repository into a new project directory on HPC, best location is `/work/` \
```bash
git clone git@github.com:mniederhuber/rstudio-singularity.git
```

2. build the singularity image - assumes installation of apptainer 
Feel free to change the location and name of the .sif output. 
But be mindful that you'll then need to provide the correct path to the .sif when running the container in step 3. 
```bash
module load apptainer
apptainer build builds/bio_dev.sif defFiles/bio_dev.def
```
3. Start up rstudio server \
This script does a few things... \
It makes some temporary directors for server stuff, \
writes a brief `rsession.conf` file with a couple paths to define default working directory \
It then binds some paths to the container and executes rstudio server with the container. 

Currently you'll to pass the singularity image path to the script. 
This is necessary so that the container can bind your working directory (where you launch the script from) and still find the .sif image. 
```bash
sbatch scripts/runStudio.sh builds/bio_dev.sif
```

3. start a tunnel from your local machine \
Check the slurm out file for deets. 
#TODO make this more accessible, print to stdout?

```bash
ssh -N -L 8989:${remote.HOSTNAME}:${remote.PORT} ${USER}@longleaf.unc.edu
```

4. open rstudio in browser at `http://localhost:8989` and enter credentials

5. `renv` is included in the container installation and can then be used to track package versions \


# Extending the image

It's straightforward to extend the image by adding desired packages/software to the `.def` file.
However, the image will then have to be rebuilt.

#TODO add more details on how to add software and other containers that might be useful to pull.
ie. bioconductor containers

# notes

- use bioconductor image as base and extend as needed
	- needs rstudio and rstudio server
	- needs magrittr, dplyr, other tidyverse, ggplot2o

bioconductor_docker image has `rocker/rstudio` as base image
https://github.com/Bioconductor/bioconductor_docker


