#!/bin/python
# -*- coding: utf-8 -*-

import jenkins
import sys
import config

JENKINS_SERVER = config.JENKINS_SERVER
JENKINS_USERNAME = config.JENKINS_USERNAME
JENKINS_PASSWORD = config.JENKINS_PASSWD
JENKINS_JOBNAME = sys.argv[1]

report_table = """ <table style="width:75%" border="1">
    <tr>
    <th>Commit message</th>
    <th>Files Affected</th>
    <th>Author</th>
    </tr>
    """

server = jenkins.Jenkins(JENKINS_SERVER, username=JENKINS_USERNAME, password=JENKINS_PASSWORD)
current_build_number = server.get_job_info(JENKINS_JOBNAME)['lastBuild']['number']
build_info = server.get_build_info(JENKINS_JOBNAME, current_build_number)

for i in range(len(build_info['changeSet']['items'])):
    msg = build_info['changeSet']['items'][i]['msg']
    author = build_info['changeSet']['items'][i]['author']['fullName']
    file = ""
    for j in range(len(build_info['changeSet']['items'][i]['paths'])):
        file += build_info['changeSet']['items'][i]['paths'][j]['file'] + "<br>"
    report_table+="""<tr>
              <td>%s</td>
              <td>%s</td>
              <td>%s</td>
              </tr> """ % (msg, file, author)
report_table+="""</table>"""

html_report_file = "build_changeset.html"
html_file = open(html_report_file,"w")
if(report_table.find('<td>') != -1):
    html_title = """<h3>Changelog</h3><br/>"""
    html_file.write(html_title)
    html_file.write(report_table)
html_file.close()

