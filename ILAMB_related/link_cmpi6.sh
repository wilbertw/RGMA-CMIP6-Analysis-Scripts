#!/usr/bin/env bash

#set -x 


cmipdir="/global/cscratch1/sd/cmip6/CMIP6/"

mipname="LS3MIP"
expname="land-hist"
ensname="r1i1p1f1"
dmnames=(Lmon Amon)
linkdir=/global/homes/m/minxu/scratch/CMIP6_ILAMB/LS3MIP_MODEL/


### PLEASE CHANGE ABOVE VARIABLES TO FIX YOUR NEED !!! ###


workdir=`pwd`

for domname in "${dmnames[@]}"; do
     out=(`ls  $cmipdir/$mipname/*/*/$expname/$ensname/$domname/*/*/*/ -d`)
     
     
     for mdname in "${out[@]}"; do 
         if [[ $mdname =~ $cmipdir/$mipname/(.*)/(.*)/$expname/$ensname/$domname/(.*)/(g.*)/(v.*)/ ]]; then
            ctrname=${BASH_REMATCH[1]}
            modname=${BASH_REMATCH[2]}
            varname=${BASH_REMATCH[3]}
            grdname=${BASH_REMATCH[4]}
            vername=${BASH_REMATCH[5]}
     
     
            #echo $modname $varname $grdname $vername
     
            out=(`ls $cmipdir/$mipname/$ctrname/$modname/$expname/$ensname/$domname/$varname/`)
     
            numgrid=${#out[@]}
            if [[ ${#out[@]} -ne 1 ]]; then
                echo ${#out[@]}
     
                if [[ $grdname -eq 'gn' ]]; then
                   continue
                fi
     
                echo "xxxxx"
            fi
     
     
            out=(`ls $cmipdir/$mipname/$ctrname/$modname/$expname/$ensname/$domname/$varname/$grdname`)
            numvern=${#out[@]}
            #echo $numvern
     
            if [[ $numvern -ne 1 ]]; then
     
                IFS=$'\n' sorted=($(sort <<<"${out[*]}"))
                unset IFS
     
     
               if [[ "$vername" != ${sorted[-1]} ]]; then
                  #echo "skip" $vername
                  continue
               fi
            fi
     
           
            echo $mdname
     
            apath=`readlink -f $mdname`
     
      
            echo $apath
     
     
            if [[ ! -d $linkdir/$modname ]]; then
                cd $linkdir && mkdir $modname
            fi
     
            cd $linkdir/$modname && ln -sf $apath/*.nc .
     
            #cd $linkdir && mkdir ${BASH_REMATCH[2]}
            #cd $workdir
            #cd $linkdir/${BASH_REMATCH[2]} && ln -sf $workdir/$mdname/* .
     
            #need to check again to remove the gn gr grid and different version
     
            
      
     
            cd $workdir
         else
            echo "no match"
         fi
     done

done
