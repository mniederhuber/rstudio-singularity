# Rstudio + Singularity + renv Template

The purpose of the template is to provide a starting point for bioinformatics projects using R with a focus on environment management using a combination of `singularity`/`apptainer` and `renv`.

The template is designed for use on an HPC cluster, and specifically setup for use with the UNC-Chapel Hill cluster Longleaf.
Though it could likely be used on other HPC systems with *minimal* adjustments.     

# Suggested setup

## 1. Clone this repository into a new project directory.

```bash
git clone git@github.com:mniederhuber/rstudio-singularity.git
```
> **NOTE** \
> By default the build and run scripts assume that the project working directory is the `$PWD` where the scripts are run. \
> eg. a project parent directory that contains this repo `project/rstudio-singularity` will be the working directory if the scripts are run from `project/`. 

## 2. Pull a container image from dockerhub

There are a number of container images available that have RStudio Server.

From the Rocker Project:
- https://hub.docker.com/u/rocker
- rstudio -- https://hub.docker.com/r/rocker/rstudio
- rstudio + tidyverse -- https://hub.docker.com/r/rocker/tidyverse
- rstudio + ml packages -- https://hub.docker.com/r/rocker/ml

From Bioconductor:
- rstudio + bioconductor -- https://hub.docker.com/r/bioconductor/bioconductor

Bioconductor images are built off of Rocker images. Take a look at [The Rocker Project](https://rocker-project.org/) and [bioconductor_docker](https://github.com/Bioconductor/bioconductor_docker) for more details.

> I've been using: [RELEASE_3_19-R-4.4.1](https://hub.docker.com/layers/bioconductor/bioconductor/RELEASE_3_19-R-4.4.1/images/sha256-4ad625d91f659345aa3d60a9c9a4713517c0c1c7af265806fe6820eddab17ed4?context=explore) without a problem, which sets the Bioconductor verstion to 3.19 and R to 4.4.1

When you have a container picked out run the following in your project directory. Replace " 
```bash
module load apptainer
apptainer pull docker://bioconductor/bioconductor:RELEASE_3_19-R-4.4.0
```
The image will be cached in your `$HOME` directory, and you can easily move or copy the `.sif` file that apptainer generates to wherever you want.

## 3. Start up rstudio server 

The `runStudio.sh` script in this repository was written to launch RStudio server from a container on a compute node of the UNC cluster. I frankensteined this script together from a few places and it may need to be modified to run outside of UNC.

>[!WARNING]
>Make sure to customize the `runStudio.sh` SBATCH settings to fit your specific use (set partition, time, memory...).
>These are not set in the script by default. 

This script does a few things... \
- It makes some directories for server stuff: `conf/`,`tmp/`,`var/` in the project working directory. 
- Writes a brief `rsession.conf` file to define working directory for the server. 
- It then binds necessary paths including working directory to the container and executes rstudio server with the container. 

Run the script as follows with the path to your container as the first argument. 

```bash
cd $PROJECT_DIR
sbatch rstudio-singularity/src/runStudio.sh $PATH_TO_YOUR_CONTAINER
```

## 4. Start a tunnel from your local machine 

Because we can't easily launch a browser from the cluster we need to use or local computer's browser. To do this we have to tunnel between our local machine and the cluster node running the server. 

A "tunnel" is just a connection between two networks that allows data to move between them.

The `runStudio.sh` script will generate an output file `var/logs/studio-<jobID>.out` with the following info:
- name of your container
- port for connecting
- cluster node id 
- a random password for Rstudio login

You can copy the necessary command to start the tunnel from your local machine. It will look something like this:
```bash
ssh -N -L 8989:${remote.HOSTNAME}:${remote.PORT} ${USER}@longleaf.unc.edu
```

This command sets up a secure tunnel from local port 8989 (you can change this to essentially any port number), to the remote cluster node address, which is listening on the assigned remote port. 

You will be prompted for your normal cluster login info. And then you may get a warning message or nothing may happen, which is a good thing. 

## 4. Open rstudio in browser 

Open any web browser and go to `http://localhost:8989` . If the server launced correctly and your tunnel is working you should get an RStudio login prompt. Use your onyen and the password generated in `var/logs/studio-<jobID>.out` to login.

The port address you used to start the tunnel (8989 in the example above) must match. So if you changed your local port to `8990` you'll need to point the browser to `http://localhost:8990`.  

You should now have a running rstudio server with the base bioconductor container.  

# Installing more packages! 

Each data analysis project is unique and will need different packages. \
One approach is to manually add packages to the definition file and rebuild the image as needed. \
This is tedious and time consuming.\

Instead it's recommended that `renv` be used to manage all additional package installations. \
Read the `renv` docs for more details. 
https://rstudio.github.io/renv/articles/renv.html

Briefly:
## 1. Initialize renv

> If you have not used renv before you may need to install it.

```R
renv::init()
```

## 2. Install any new packages with `renv::install()`\
This will create a project specific library of packages. BUT! `renv` also builds and sources a *global* cache of packages. So each project just has symlinks to the cached package. 

Example:
```R
renv::install('ggplot2')
``` 
or from bioconductor...
```R
renv::install('bioc::GenomicRanges')
```

## 3.Track packages 
Capture the state of your project with `renv::snapshot()`

As you use more packages in your code, `snapshot()` will update the `.lockfile` with the packages and versions. 

# Publishing and sharing analysis

Once the singularity image has been built for a project it will provide a static base environment.

With careful use of `renv` the renv `.lockfile` will then provide package tracking for reproducibility.

When it's time to publish or share analysis there are two options. 

1. The container image can either be shared directly by file transfer

2. You can simply point others to the container you used on dockerhub 
> Be careful if you did not specify a particular tag for the container you pulled and just grabbed the latest or development version. This could mean that the container you point someone else to may be updated from what you originally used. 

3. Setup your own dockerhub account and upload the image you used. 




