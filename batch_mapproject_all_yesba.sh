#!/bin/bash

if [ "$#" -lt 4 ]; then echo Usage: $0 dem.tif list.txt baPrefix currDir; exit; fi

dem=$1
list=$2
baPrefix=$3
currDir=$4

cd $currDir

export ISISDATA=$HOME/projects/isis3data
export ISISROOT=$HOME/miniconda3/envs/isis5.0.1
export ALESPICEROOT=$ISISDATA
s=StereoPipeline-3.1.1-alpha-2022-08-06-x86_64-Linux
export PATH=/home6/oalexan1/projects/BinaryBuilder/$s/bin:$PATH

# Run batches

w=30
num_images=$(cat $list |wc | ~/bin/print_col.pl 1)
((num_batches=num_images/w))
((num_images2 = num_batches * w))
if [[ "$num_images2" -lt "$num_images" ]]; then ((num_batches++)); fi
echo Batch size $w
echo num_images=$num_images
echo num_batches=$num_batches

for ((i = 0; i < num_batches; i++)); do
    ((beg=i*w)); ((end=beg+w));
    qsub -m n -r n -N $(dirname ${baPrefix})_$beg -l walltime=6:00:00 \
        -W group_list=s7369 -j oe -S /bin/bash                  \
        -l select=1:ncpus=20:model=ivy --                       \
        ~/projects/sfs/batch_mapproject_yesba.sh $dem $list $baPrefix $beg $end $currDir
done
