#!/usr/bin/env bash


# Please modify the following variables accordingly

#--------------------------------------------------------------------------------------
cmipdir=THE_CMIP6_TOP_DIRECTORY
mipname=LS3MIP
expname=land-hist
ensname='*'
dmnames=(fx Lmon Amon Emon)
linkdir=THE_LINKED_DIRECTORY
#--------------------------------------------------------------------------------------




# Do not modify below
cmrvars=($(cat cmip.cfg |grep -i ^variable  |cut -d = -f2 |sed 's/"//g'))
altvars=($(cat cmip.cfg |grep -i ^alternate |cut -d = -f2 |sed 's/"//g'))
dervars=($(cat cmip.cfg |grep -i ^derived   |cut -d = -f2 |sed 's/"//g'))

varsarr+=(${cmrvars[@]})
varsarr+=(${altvars[@]})

for v in "${dervars[@]}"; do
    varsarr+=($(echo $v |sed  's/[+-]/ /g'|sed 's/"//g'))
done

declare -A uniq 
for i in "${varsarr[@]}"; do uniq["$i"]=1; done
incVars=(${!uniq[@]})
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
     

            # skip
            if [[ ${#ArrayName[@]} -gt 0 && ! " ${incmodels[@]} " =~ " ${modname} " ]]; then
               continue
            fi

	    if [[ ! " ${incVars[@]} " =~ " ${varname} " ]]; then
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

               # expand to other mip and ensemble same model and grdname
               if [[ ${testland[$modname]} != $landfrc || ${testarea[$modname]} != $areacel ]]; then

                  echo "cannot find areacella and landfrac variables, try to find them in other MIP/experiments!!!"
		  file_landfrac=""
		  file_areacell=""

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
		      else
			 xmodname=$modname
                      fi
                      
                      if [[ ! -d $linkdir/$xmodname ]]; then
                          cd $linkdir && mkdir $xmodname
                      fi

		      if [[ ${testland[$modname]} != $landfrc && ! -z "$file_landfrac" ]]; then

                         apath=`readlink -f $file_landfrac`
			 echo "link ..." $apath $linkdir/$xmodname
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

            # if there are many grids, skip the native one as they are usually cubed sphere grids
            outgrd=(`ls $cmipdir/$mipname/$ctrname/$modname/$expname/$ensname/$domname/$varname/`)
            numgrid=${#outgrd[@]}
            if [[ ${#outgrd[@]} -ne 1 ]]; then
                echo ${#outgrd[@]}
     
                if [[ $grdname -eq 'gn' ]]; then
                   continue
                fi
            fi
     
     
            # find the latest version
            outver=(`ls $cmipdir/$mipname/$ctrname/$modname/$expname/$ensname/$domname/$varname/$grdname`)
            numvern=${#outver[@]}
            if [[ $numvern -ne 1 ]]; then
                IFS=$'\n' sorted=($(sort <<<"${outver[*]}"))
                unset IFS
                if [[ "$vername" != ${sorted[-1]} ]]; then
                   continue
                fi
            fi
     
           
            apath=`readlink -f $mdname`
     
	    if [[ "$ensname" != "r1i1p1f1" ]]; then
		   modname=$modname-$ensname
            fi
     
     
            if [[ ! -d $linkdir/$modname ]]; then
                cd $linkdir && mkdir $modname
            fi
     
            cd $linkdir/$modname && ln -sf $apath/*.nc .

            cd $workdir
         else
            echo "no match"
         fi
     done
done
