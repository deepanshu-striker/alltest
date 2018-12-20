#!/bin/python
# -*- coding: utf-8 -*-

import datetime
import json
import urllib2
import requests
import base64
import config

repoList = ['contego','contegoclient','workloadmanager','workloadmanager-client','horizon-tvault-plugin','documentation','automation','tempest','cfg-scripts','cloudforms','POCs']
username = config.GIT_USERNAME
pwd = config.GIT_PASSWD

report_table = """ <table style="width:100%" border="1">
    <tr>
    <th>Repository</th>
    <th>Pull Request</th>
    <th>Owner</th>
    <th>Open for #days</th> 
    <th>Review Status</th>
    </tr>
    """
    
report_table1 = """ <table style="width:100%" border="1">
    <tr>
    <th>Repository</th>
    <th>Pull Request</th>
    <th>Owner</th>
    <th>Open for #days</th> 
    <th>Review Status</th>
    </tr>
    """

def sendGETRequest(url, headers):
    apiRequest = urllib2.Request(url)
    apiRequest.add_header("Authorization", "Basic %s" % headers)
    apiRequest.add_header("Content-Type", "application/json")
    apiResponse = urllib2.urlopen(apiRequest)
    return apiResponse

for repo in repoList:
    apiurl = "https://api.github.com/repos/trilioData/" + str(repo) + "/pulls"
    headers = base64.encodestring('%s:%s' % (username, pwd)).replace('\n', '')
    pullReqList = json.load(sendGETRequest(apiurl, headers))
    currentDate = datetime.datetime.today()
    
    for i in range(0,len(pullReqList)):
        url = pullReqList[i]['html_url']
        created_at = pullReqList[i]['created_at']
	if(pullReqList[i]['head']['repo'] != None):
	    owner = pullReqList[i]['head']['repo']['owner']['login']
	else:
	    owner = None
        assigneeList = pullReqList[i]['assignees']
        state = pullReqList[i]['state']
        title = pullReqList[i]['title']
        updated_at = pullReqList[i]['updated_at']
        getReviews = json.load(sendGETRequest(apiurl + "/" + str(pullReqList[i]['number']) + "/reviews", headers)) 
        reviewStateList = []
        for j in range(0,len(getReviews)):
              reviewStateList.append(getReviews[j]['state'])
        if (len(reviewStateList) > 0):
            rstate = reviewStateList[len(reviewStateList)-1]
        else:
            rstate = "NOT REVIEWED"
        rstate = rstate.title()
        idays = (currentDate - datetime.datetime.strptime(created_at,'%Y-%m-%dT%H:%M:%SZ')).days
        if(datetime.datetime.strptime(created_at,'%Y-%m-%dT%H:%M:%SZ').date() > datetime.date(2017, 04, 01)):
            if(rstate != "Not Reviewed"):
                if(currentDate - datetime.timedelta(days=2)).date() > datetime.datetime.strptime(created_at,'%Y-%m-%dT%H:%M:%SZ').date():
                    report_table+="""<tr>
                          <td>%s</td>
                          <td><a href=%s><font color="%s">%s</font></a></td>
                          <td><font color="%s">%s</font></td>
                          <td><font color="%s">%s</font></td>
                          <td><font color="%s">%s</font></td>
                          </tr> """ % (repo, url, "red", url, "red", owner, "red", idays, "red", rstate)
            else:
                report_table1+="""<tr>
                      <td>%s</td>
                      <td><a href=%s><font color="%s">%s</font></a></td>
                      <td><font color="%s">%s</font></td>
                      <td><font color="%s">%s</font></td>
                      <td><font color="%s">%s</font></td>
                      </tr> """ % (repo, url, "red", url, "red", owner, "red", idays, "red", rstate)
                      
report_table+="""</table>"""
report_table1+="""</table>"""

html_report_file="pullrequests.html"
html_file= open(html_report_file,"w")
if(report_table.find('<td>') != -1):
   html_file.write(report_table)
   if(report_table1.find('<td>') != -1):
       html_file.write("<br/><br/>")
       html_file.write("Pull requests yet to be reviewed")
       html_file.write("<br/>")
       html_file.write(report_table1)
else:
    html_file.write("No open pull requests for more than past 3 days")
html_file.close()

