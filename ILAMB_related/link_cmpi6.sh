#!/usr/bin/env bash

set -x 

cmipdir="/global/cfs/projectdirs/m3522/cmip6/CMIP6/"
mipname="LS3MIP"
expname="land-hist"
#mipname="CMIP"
#expname="historical"
#ensname="r1i1p1f1"
ensname='*'
dmnames=(fx Lmon Amon Emon)
#linkdir=/global/cfs/projectdirs/m2467/prj_minxu/elm_ls3mip/
linkdir=/global/cfs/projectdirs/m2467/prj_minxu/temp2/


#incmodels=(BCC-CSM2-MR BCC-ESM1 CESM2-WACCM CESM2 CanESM5 EC-Earth3-Veg GISS-E2-1-G INM-CM4-8 IPSL-CM6A-LR) 
incmodels=()

landfrc="sftlf"
areacel="areacella"

if [[ ! -d $linkdir ]]; then
    mkdir -p $linkdir
fi


declare -A testland
declare -A testarea

### PLEASE CHANGE ABOVE VARIABLES TO FIT YOUR NEED !!! ###

workdir=`pwd`

for domname in "${dmnames[@]}"; do
     
     out=(`ls  $cmipdir/$mipname/*/*/$expname/*/$domname/*/*/*/ -d`)

     for mdname in "${out[@]}"; do 

	 if [[ $mdname =~ $cmipdir/$mipname/(.*)/(.*)/$expname/(.*)/$domname/(.*)/(g.*)/(v.*)/ ]]; then
            ctrname=${BASH_REMATCH[1]}
            modname=${BASH_REMATCH[2]}
	    ensname=${BASH_REMATCH[3]}
            varname=${BASH_REMATCH[4]}
            grdname=${BASH_REMATCH[5]}
            vername=${BASH_REMATCH[6]}

	    testland[$modname]=""
	    testarea[$modname]=""
     
	    if [[ "$modname" == "CNRM-CM6-1" ]]; then
                echo $modname $varname $grdname $vername $mdname
            fi


            if [[ ${#ArrayName[@]} -gt 0 && ! " ${incmodels[@]} " =~ " ${modname} " ]]; then
               continue
            fi


            if [[ $domname == 'fx' && (${testland[$modname]} != $landfrc || ${testarea[$modname]} != $areacel) ]]; then

	       # try to find area and sftlf under the mip and ens directories first
	       # link will be done with other variables
               tmp=(`ls $cmipdir/$mipname/$ctrname/$modname/$expname/$ensname/$domname/`)
               if [[ ${tmp[*]} =~ $landfrc ]]; then
                   testland[$modname]=$landfrc
               fi

               if [[ ${tmp[*]} =~ $areacel ]]; then
                   testarea[$modname]=$areacel
               fi

	       if [[ $modname == "CNRM-ESM2-1" ]]; then
                   echo testland[$modname],  testarea[$modname]
		   if [[ ${testland[$modname]} != $landfrc ]]; then
			   echo noeq true
		   else
			 echo equal ${tmp[*]}
	            fi
		   echo ${testarea[$modname]} != $areacel
	       fi

               # expand to other mip and ensemble same model and grdname
               if [[ ${testland[$modname]} != $landfrc || ${testarea[$modname]} != $areacel ]]; then
                  #/global/homes/m/minxu/CMIP6/CMIP/NCAR/CESM2/*/r1i1p1f1/fx/sftlf/gn/v20190308
                  #tmp=(`ls $cmipdir/CMIP/$ctrname/$modname/*/r1i1p1f1/fx/$landfrc/$grdname/* -d`)

                  searchmips=( $mipname 'CMIP' )
		  for mip in "${searchmips[@]}"; do

                      tmp=(`ls $cmipdir/$mip/$ctrname/$modname/*/*/fx/$landfrc/$grdname/* -d`)
                      for t in "${tmp[@]}"; do
                         file_landfrac=`ls $t/*.nc`
                         break
		      done

                      tmp=(`ls $cmipdir/$mip/$ctrname/$modname/*/*/fx/$areacel/$grdname/* -d`)
                      for t in "${tmp[@]}"; do
                         file_areacell=`ls $t/*.nc`
                         break
		      done

	              if [[ "$ensname" != "r1i1p1f1" ]]; then
	                 xmodname=$modname-$ensname
                      fi
                      
                      if [[ ! -d $linkdir/$xmodname ]]; then
                          cd $linkdir && mkdir $xmodname
                      fi

		      if [[ ${testland[$modname]} != $landfrc && ! -z "$file_landfrac" ]]; then
                         apath=`readlink -f $file_landfrac`
                         cd $linkdir/$xmodname && ln -sf $apath . && cd  $workdir
                         testland[$modname]=$landfrc
		      fi

		      if [[ ${testarea[$modname]} != $areacel && ! -z "$file_areacell" ]]; then
                         apath=`readlink -f $file_areacell`
                         cd $linkdir/$xmodname && ln -sf $apath . && cd  $workdir
                         # set the declare
                         testarea[$modname]=$areacel
		      fi

                      if [[ ${testland[$modname]} == $landfrc && ${testarea[$modname]} == $areacel ]]; then
                          break
		      fi 
		  done
               fi
            fi


            outgrd=(`ls $cmipdir/$mipname/$ctrname/$modname/$expname/$ensname/$domname/$varname/`)
            numgrid=${#outgrd[@]}
            if [[ ${#outgrd[@]} -ne 1 ]]; then
                echo ${#outgrd[@]}
     
                if [[ $grdname -eq 'gn' ]]; then
                   continue
                fi
     
                echo "xxxxx"
            fi
     
     
            outver=(`ls $cmipdir/$mipname/$ctrname/$modname/$expname/$ensname/$domname/$varname/$grdname`)
            numvern=${#outver[@]}
            #echo $numvern
     
            if [[ $numvern -ne 1 ]]; then
     
                IFS=$'\n' sorted=($(sort <<<"${outver[*]}"))
                unset IFS
     
     
               if [[ "$vername" != ${sorted[-1]} ]]; then
                  #echo "skip" $vername
                  continue
               fi
            fi
     
           
            echo 'zzzz', $mdname
     
            apath=`readlink -f $mdname`
     
      
            #echo $apath

	    if [[ "$ensname" != "r1i1p1f1" ]]; then
		   modname=$modname-$ensname
            fi
     
     
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
