#! /bin/bash
#SBATCH -t 1:00:00
#SBATCH -p general
#SBATCH --mem=4G
#SBATCH -o build-%j.out
#SBATCH -e build-%j.err

if [ ! -d builds ];
	mkdir builds
fi

defFile="defFile/bio_dev.def"
sifFile=$(basename $defFile .def).sif

module load apptainer

apptainer build builds/$sifFile $defFile

