#!/bin/python
# -*- coding: utf-8 -*-

from jira import JIRA
import sys
import config

username = config.JIRA_USERNAME
pwd = config.JIRA_PASSWD
url = config.JIRA_URL

options = {'server': url}
jira = JIRA(options,basic_auth=(username, pwd))

jql_str = """(NeedToAutomate != EMPTY OR labels  in (NeedToAutomate) OR component in (NeedToAutomate)) AND (labels = EMPTY OR labels not in (automated))"""
newIssues = jira.search_issues(jql_str, maxResults=1000, fields="key,summary,status,labels,customfield_10100,customfield_10101,customfield_11607", json_result=True)

report_table_new = """ <table style="width:100%" border="1">
    <tr>
    <th>JIRA ID</th>
    <th>Summary</th>
    <th>Status</th>
    <th>Found In Build</th>
    <th>Fixed In Build</th>
    <th>Labels</th>
    </tr>
    """
count = len(newIssues['issues'])

for new in newIssues['issues']:
    jira_id = new['key']
    jira_summary = new['fields']['summary']
    jira_status = new['fields']['status']['name']
    jira_found_in_build = []
    if(new['fields']['customfield_10100'] != None):
        for id in new['fields']['customfield_10100']:
	    jira_found_in_build.append(str(id))
    jira_fixed_in_build = new['fields']['customfield_10101']
    jira_needtoautomate = []
    if(new['fields']['customfield_11607'] != None):
        for val in new['fields']['customfield_11607']:
	    jira_needtoautomate.append(str(val['value']))
    if(len(new['fields']['labels']) > 0):
	jira_labels = new['fields']['labels']
    else:
	jira_labels = None
    jira_url = "https://triliodata.atlassian.net/browse/" + str(jira_id)
    
    report_table_new+="""<tr>
          <td><a href=%s>%s</a></td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          <td>%s</td>
          </tr> """ % (jira_url, jira_id, jira_summary, jira_status, jira_found_in_build, jira_fixed_in_build, jira_labels)

report_table_new+="""</table>"""

html_report_file = "tobeautomated_jiras.html"
html_file = open(html_report_file,"w")
if(report_table_new.find('<td>') != -1):
    html_title = """<h3><font color=%s>To be automated JIRAs:- Count: %s</font></h3><br/>""" % ("blue", count)
    html_file.write(html_title)
    html_file.write(report_table_new)
    html_file.write("<br/><br/>")
html_file.close()

