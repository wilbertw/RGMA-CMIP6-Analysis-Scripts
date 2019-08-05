#!/usr/bin/env bash

#set -x 


expname="1pctCO2"
expname="amip"
ensname="r1i1p1f1"


dmnames=(Lmon Amon)

linkdir=/global/homes/m/minxu/scratch/CMIP6_ILAMB/MODEL/
workdir=`pwd`

for domname in "${dmnames[@]}"; do
     out=(`ls  CMIP6/CMIP/*/*/$expname/$ensname/$domname/*/*/*/ -d`)
     
     
     for mdname in "${out[@]}"; do 
         if [[ $mdname =~ CMIP6/CMIP/(.*)/(.*)/$expname/$ensname/$domname/(.*)/(g.*)/(v.*)/ ]]; then
            ctrname=${BASH_REMATCH[1]}
            modname=${BASH_REMATCH[2]}
            varname=${BASH_REMATCH[3]}
            grdname=${BASH_REMATCH[4]}
            vername=${BASH_REMATCH[5]}
     
     
            #echo $modname $varname $grdname $vername
     
            out=(`ls CMIP6/CMIP/$ctrname/$modname/$expname/$ensname/$domname/$varname/`)
     
            numgrid=${#out[@]}
            if [[ ${#out[@]} -ne 1 ]]; then
                echo ${#out[@]}
     
                if [[ $grdname -eq 'gn' ]]; then
                   continue
                fi
     
                echo "xxxxx"
            fi
     
     
            out=(`ls CMIP6/CMIP/$ctrname/$modname/$expname/$ensname/$domname/$varname/$grdname`)
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
