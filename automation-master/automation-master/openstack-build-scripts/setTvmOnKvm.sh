set -x

#Mount NFS Share
if mountpoint -q /mnt/build-vault
then
   echo "NFS already mounted"
else
   echo "NFS not mounted. Mounting.."
   mkdir -p /mnt/build-vault
   mount -t nfs 192.168.1.20:/mnt/build-vault /mnt/build-vault
   if [ $? -ne 0 ]
   then
     echo "Error occured in NFS mount, exiting.."
     exit 1
   fi
fi

setvars()
{
        clear
        iFlag="y"
        TVAULT_ISO="/opt/"
        MEM=12288
        CPUs=4
        BRIDGE=`brctl show | awk '{print $1}' | head -2 | tail -1`
        imageTargetLoc="/var/lib/libvirt/images"
        tempFile="/tmp/temp.txt"
        ipCount=$IP_COUNT
        ip=($TVAULT_IP)
        tvmName=$TVAULT_NAME
        imagePath="/home/build/"
        rm -rf $imagePath$tvmName
	      rm -rf /tmp/$tvmName/*
        mkdir -p $imagePath$tvmName
	      mkdir -p $imageTargetLoc/$tvmName
	      mkdir -p /tmp/$tvmName
	      USER_DATA="/tmp/$tvmName/user-data"
        META_DATA="/tmp/$tvmName/meta-data"
        cp /mnt/build-vault/master/tvault-appliance-os-$TVAULT_VERSION.qcow2.tar.gz $imagePath$tvmName
        validate
}

cleanUp()
{
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
		            rm -rf ${imageTargetLoc}/${tvmname}/${imageFile}*
                rm -f ${TVAULT_ISO}${tvmName}_${iTemp}.iso ${USER_DATA}_${tvmName}_${iTemp} ${META_DATA}_${tvmName}_${iTemp}
        done
}

validate()
{
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                virsh shutdown ${tvmName}_${iTemp}
                sleep 2m
                virsh undefine ${tvmName}_${iTemp}
                #sleep 1m
        done

        imageFile=`ls ${imagePath}${tvmName} | awk -F'/' '{print $NF}' | cut -d"." -f1-4`
}

showvars()
{
        echo "Values Setup...."
        echo "Image Location : ${imagePath}${tvmName}"
        echo "Image File : ${imageFile}"
        echo "TVM machines Count : ${ipCount}"
        for ((iTemp=1;iTemp<=${ipCount};iTemp++)); do
                echo "IP Address ${iTemp} : ${ip[$iTemp-1]}"
        done
}

extractAndCopy()
{
        cp ${imagePath}${tvmName}/${imageFile}.tar.gz ${imageTargetLoc}/${tvmName}/${imageFile}.tar.gz
        cd ${imageTargetLoc}/${tvmName}/
        tar xvzf ${imageFile}.tar.gz
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                cp ${imageFile} ${imageFile}_${iTemp}
        done
}

setUserData()
{
        cat > ${USER_DATA} << _EOF_
preserve_hostname: False
hostname: ${tvmName}_${iTemp}
_EOF_
}

setMetaData()
{
        cat > ${META_DATA} << _EOF_
instance-id: ${tvmName}_${iTemp}
network-interfaces: |
  auto ens3
  iface ens3 inet static
  address ${ip[$iTemp-1]}
  netmask 255.255.0.0
  gateway 192.168.1.1
  dns-nameservers 192.168.1.1 8.8.8.8
hostname: ${tvmName}_${iTemp}
_EOF_
}

setISO()
{
        genisoimage -output ${TVAULT_ISO}${tvmName}_${iTemp}.iso -volid cidata -joliet -rock ${USER_DATA} ${META_DATA}
        cp ${USER_DATA} ${USER_DATA}_${iTemp}; cp ${META_DATA} ${META_DATA}_${iTemp}
}

setDataFiles()
{
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                setUserData
                setMetaData
                setISO
        done
}

cleanCache()
{
echo "cleaning cache"
echo "for ((iTemp=1; iTemp<=5;iTemp++));do date && sync && echo 3 > /proc/sys/vm/drop_caches && sleep 5;done" > temp.sh
nohup sh temp.sh &
}

createVMs()
{
        cd ${imageTargetLoc}/${tvmName}/
        for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
                virt-install --import --name ${tvmName}_${iTemp} --memory $MEM --vcpus $CPUs --disk ${imageFile}_${iTemp},format=qcow2,bus=virtio --disk ${TVAULT_ISO}${tvmName}_${iTemp}.iso,device=cdrom --network  bridge=virbr0,model=virtio --os-type=linux --noautoconsole
                virsh change-media ${tvmName}_${iTemp} hda --eject --config		
        done
	sleep 6m
	cleanCache
}

setvars
showvars
cleanUp
setDataFiles
extractAndCopy
createVMs

for ((iTemp=1;iTemp <= ${ipCount};iTemp++)); do
        virsh reboot ${tvmName}_${iTemp}
        sleep 6m
done

echo "Finally..."
set +x

