#!/usr/bin/python
# -*- coding: utf-8 -*-
import smtplib
import sys
import os
import datetime

setups = ["Mirantis_Mitaka_V2_Ceph"]
storages = ["NFS", "SWIFT KEYSTONEV2", "SWIFT KEYSTONEV3", "SWIFT TEMPAUTH", "S3 AMAZON", "S3 REDHAT CEPH", "S3 SUSE CEPH"]
os.system("mkdir -p Report")
build_num=sys.argv[1]
tvault_ip=sys.argv[2]

html_report_file="Report/results.html"
html_file=open(html_report_file,"w")
html_file.write("Date : " + str(datetime.datetime.now()))
html_file.write("<br/>")
html_file.write("Build Number :" + str(build_num))
html_file.write("<br/>")
html_file.write("Tvault IP :" + str(tvault_ip))
html_file.write("<br/><br/>")

for i in range(0, len(setups)):
    result_table = """ <table border="1"><tr><th>TestName</th><th>Result</th></tr>"""
    test_result_file = "test_results"
    test_result_file += "_" + str(setups[i])
    html_file.write("Test Results for " + str(setups[i]))
    html_file.write("<br/><br/>")
    html_table = ""
    
    with open(test_result_file, "r") as f:
        for line in f:
            if(line == "\n"):
                pass
            elif(line.find('---') != -1):
                line = line.replace('-',' ')
                line = line.lstrip()
                line = line.rstrip()
                if(line in storages):
                    storage_name = line
                    html_table+="""<tr><th colspan=2>%s</hd></tr> """ % (storage_name)
            else:
                row = line.split()
                test_name = str(row[0])
                test_result = str(row[1])
                if(line.startswith("ERROR")):
                    text_color = "red"
                    test_result = line[6:]
                elif(test_result == "FAILED"):
                    text_color = "red"
                else:
                    text_color = "green"
                html_table+="""<tr>
                    <td><font color="%s">%s</font></td>
                    <td><font color="%s">%s</font></td>
                    </tr> """ % (text_color, test_name, text_color, test_result)
        result_table+=html_table + """</table>"""

    html_file.write(result_table)
    html_file.write("<br/><br/>")
        
html_file.close()
