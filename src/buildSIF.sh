#! /bin/bash
#SBATCH -t 1:00:00
#SBATCH -p general
#SBATCH --mem=4G
#SBATCH -o var/logs/build-%j.out
#SBATCH -e var/logs/build-%j.err


if [ ! -d "$PWD"/var/logs ]; then
	mkdir -p "$PWD"/var/logs
fi 

defFile="build/bio_dev.def"
sifFile=$(basename $defFile .def).sif

module load apptainer

apptainer build build/$sifFile $defFile

