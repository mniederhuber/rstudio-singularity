# Rstudio + Singularity Template


> GOAL
> To set up a relatively simple, reproducible, and trackable workflow for running R/Rstudio from the UNC longleaf HPC, using a combination of singularity/apptainer containerization, and renv.

> **NOTE** 
> This template is designed specifically for the UNC HPC, but could be a general guide for running rstudio-server within a container from a remote HPC. 

# Instructions
1. Clone this repository into a new project directory on HPC `<yourProject>`, best location is `/work/` \
```bash
git clone git@github.com:mniederhuber/rstudio-singularity.git
```
> **NOTE** 
> By default the build and run scripts assume that the project working directory is the `$PWD` where the scripts are run. 
> eg. a project parent directory that contains this repo `project/rstudio-singularity` will be the working directory if the scripts are run from `project/`. 

2. Build the singularity image - assumes `apptainer` is installed, it is on UNC LL. 
The output `.sif` file can be renamed as needed by manually changing the name of the definition file or creating a new definition file.
```bash
sbatch src/buildSIF.sh
```
3. Start up rstudio server \
This script does a few things... \
It makes some directories for server stuff: `conf/`,`tmp/`,`var/` in the project working directory. \
Writes a brief `rsession.conf` file to define working directory for the server. \
It then binds necessary paths including working directory to the container and executes rstudio server with the container. 

Currently you'll to pass the singularity image path to the script. 

```bash
sbatch <yourProject>/src/runStudio.sh <yourProject>/build/bio_dev.sif
```
Check that the job runs successfully by opening the job output in `var/logs/studio-<jobID>.out`

3. Start a tunnel from your local machine \
You can copy the necessary command from the job output. 
```bash
ssh -N -L 8989:${remote.HOSTNAME}:${remote.PORT} ${USER}@longleaf.unc.edu
```

4. Open rstudio in browser at `http://localhost:8989` and enter credentials

5. Profit $$$
You should now have a running rstudio server with the base tidyverse container from rocker, with `renv` added.

# Extending the image

To extend the project with additional packages create an Rproject in the project directory and then initialize `renv`. 

The current design is to allow users to install packages "on the fly" to their home directories. 

`renv` can then be used to track specific package versions being used in the project in the `.lockfile` 

# Publishing and sharing analysis

Once the singularity image has been built for a project it will provide a static base environment.
This image is relatively bare bones to keep the `.sif` relatively small.
Currently it includes the `tidyverse` packages, but this could even be removed. 
With careful use of `renv` the renv `.lockfile` will then provide any  

