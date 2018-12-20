#!/bin/bash 
source log_gather.answers &> /dev/null 
BASE_DIR="$(pwd)"
mkdir ${BASE_DIR}/logfile-tvault
################################
compu=`cat $BASE_DIR/log_gather.answers | grep Compute | cut -d "=" -f2`
echo "compu " $compu>>${BASE_DIR}/temp_file_comp
n=2
while true;do
	n=$((n+1))
	fnch=`cut -d " " -f$n temp_file_comp`
	   if [ "$fnch" == "" ];then
break
	   else
	     echo $fnch
	      scp $User_compute@$fnch:/var/log/nova/tvault-contego.log ${BASE_DIR}/logfile-tvault/tvault-contego-$fnch	

	  fi
done
################################
contr=`cat log_gather.answers | grep Controller | cut -d "=" -f2`
echo "contr " $contr>> temp_file_contr
n=2
while true;do
        n=$((n+1))
        fnch=`cut -d " " -f$n temp_file_contr`
           if [ "$fnch" == "" ];then
break
           else
             echo $fnch
              scp $User_controller@$fnch:/var/log/nova/nova-api.log ${BASE_DIR}/logfile-tvault/nova-api.log-$fnch

          fi
done
################################
tvault=`cat log_gather.answers | grep Tvault | cut -d "=" -f2`
echo "tvault " $tvault>> temp_file_tvault
n=2
while true;do
        n=$((n+1))
        fnch=`cut -d " " -f$n temp_file_tvault`
           if [ "$fnch" == "" ];then
break
           else
             echo $fnch
              scp root@$fnch:/var/log/workloadmgr/workloadmgr-workloads.log ${BASE_DIR}/logfile-tvault/tvault-wokloadmgr.log-$fnch

          fi
done
################################

tar -zcvf "tvault-$(date '+%y-%m-%d').tar.gz" logfile-tvault
rm -f ${BASE_DIR}/temp_file_comp
rm -f ${BASE_DIR}/temp_file_contr
rm -f ${BASE_DIR}/temp_file_tvault
rm -rf ${BASE_DIR}/logfile-tvault

echo "Please find the logs in tar format in ${BASE_DIR}"
