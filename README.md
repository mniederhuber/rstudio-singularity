# Rstudio + Singularity + renv Template

The purpose of the template is to provide a starting point for bioinformatics projects using R with a focus on environment management using a combination of `singularity`/`apptainer` and `renv`.

The template is designed for use on an HPC cluster, and specifically setup for use with the UNC-Chapel Hill cluster Longleaf.
Though it could likely be used on other HPC systems with *minimal* adjustments.     

# Suggested setup
1. Clone this repository into a new project directory.
```bash
git clone git@github.com:mniederhuber/rstudio-singularity.git
```
> **NOTE** \
> By default the build and run scripts assume that the project working directory is the `$PWD` where the scripts are run. \
> eg. a project parent directory that contains this repo `project/rstudio-singularity` will be the working directory if the scripts are run from `project/`. 

2. Build the singularity image.\
The output `.sif` file can be renamed as needed by manually changing the name of the definition file or creating a new definition file.

```bash
cd rstudio-singularity
sbatch src/buildSIF.sh
```
>**NOTE**\
The build script uses `apptainer` to allow for building remotely on an HPC where users don't usually have root priviledges. \
Running the build with `singularity` on remote HPC has resulted in errors. \

3. Start up rstudio server \
This script does a few things... \
It makes some directories for server stuff: `conf/`,`tmp/`,`var/` in the project working directory. \
Writes a brief `rsession.conf` file to define working directory for the server. \
It then binds necessary paths including working directory to the container and executes rstudio server with the container. \
Currently you'll to pass the singularity image path to the script. \

```bash
cd $PROJECT_DIR
sbatch rstudio-singularity/src/runStudio.sh rstudio-singularity/build/bio_dev.sif
```

3. Start a tunnel from your local machine \
The `runStudio.sh` script will generate an output file `var/logs/studio-<jobID>.out` with the port,cluster host, and generated password needed to connect to the rserver.\
You can copy the necessary command to start the tunnel from your local machine. \
It will look something like this:
```bash
ssh -N -L 8989:${remote.HOSTNAME}:${remote.PORT} ${USER}@longleaf.unc.edu
```

4. Open rstudio in browser at `http://localhost:8989` and enter credentials

You should now have a running rstudio server with the base bioconductor container, with `renv` added.

# Installing more packages! 

Each data analysis project is unique and will need different packages. \
One approach is to manually add packages to the definition file and rebuild the image as needed. \
This is tedious and time consuming.\

Instead it's recommended that `renv` be used to manage all additional package installations. \
Read the `renv` docs for more details. 
https://rstudio.github.io/renv/articles/renv.html

Briefly:
1. Initialize renv
```R
renv::init()
```

2. Install any new packages with `renv::install()`\
This will create a project specific library of packages. \
BUT! `renv` also builds and sources a *global* cache of packages.\
So each project just has symlinks to the cached package. \
Example:
```R
renv::install('ggplot2')
``` 
or from bioconductor...
```R
renv::install('bioc::GenomicRanges')
```

3.Track packages used in your project with `renv::snapshot()`\
As you use more packages in your code, `snapshot()` will update the `.lockfile` with the packages and versions. 

# Extending the image

This template is designed around the idea that the image itself should not be further extended.\
However, it can be extended by explicitly adding desired packages to the singularity `bio_dev.def` file. \
Or by changing the base dockerfile that singularity/apptainer builds from in the `bio_dev.def` file.

# Publishing and sharing analysis

Once the singularity image has been built for a project it will provide a static base environment.\
This image is relatively bare bones to keep the `.sif` small.\
Currently it is based on the `bioconductor/bioconductor_docker:RELEASE_3_18`, which is itself based on `rocker/rstudio:4.1.0` and `unbuntu 20.04`. \
With careful use of `renv` the renv `.lockfile` will then provide package tracking for reproducibility.

When it's time to publish or share analysis there are two options. \

1. The container image can either be rebuilt from the definition file, and packages can be installed from `renv`. \
[!note] this may cause a problem any of the underlying dependencies installed by the rocker script have changed... *but generally should produce the a nearly identical environment*\

2. The container image itself can be shared. \
The image can either be uploaded to `dockerhub` or shared directly. \
Dockerhub probably provides the best option for analysis that is associated with a publication.





