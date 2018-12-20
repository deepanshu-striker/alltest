#!/bin/python
# -*- coding: utf-8 -*-

from jira import JIRA
import sys
import config 

target_version = sys.argv[1]
username = config.JIRA_USERNAME
pwd = config.JIRA_PASSWD
url = config.JIRA_URL

options = {'server': url}
jira = JIRA(options,basic_auth=(username, pwd)) 

jql_str = """type != Test AND "Target Version"= """ + str(target_version)
newIssues = jira.search_issues(jql_str, maxResults=1000, fields="key,summary,assignee,reporter,status,priority", json_result=True)

report_table_new = """ <table style="width:100%" border="1">
    <tr>
    <th>JIRA ID</th>
    <th>Summary</th>
    <th>Status</th>
    <th>Assignee</th>
    <th>Priority</th>
    </tr>
    """
report_table_dev = report_table_new
report_table_qa = report_table_new
report_table_input = report_table_new
inew = idev = iinput = iqa = 0


for new in newIssues['issues']:
    jira_id = new['key']
    jira_summary = new['fields']['summary']
    jira_status = new['fields']['status']['name']
    jira_priority = new['fields']['priority']['name']
    if(new['fields']['assignee'] is None):
        jira_assignee = "Unassigned"
    else:
        jira_assignee = new['fields']['assignee']['displayName']
    jira_url = "https://triliodata.atlassian.net/browse/" + str(jira_id)
    
    color = "black"
    if(jira_priority == "Blocker" and jira_status != "Resolved"):
        color = "red"
    row = """<tr>
              <td><a href={0}>{1}</a></td>
              <td><font color={6}>{2}</font></td>
              <td><font color={6}>{3}</font></td>
              <td><font color={6}>{4}</font></td>
	      <td><font color={6}>{5}</font></td>
              </tr> """.format(jira_url, jira_id, jira_summary, jira_status, jira_assignee, jira_priority, color)

    if(jira_status == "New"):
        inew += 1
        report_table_new += row
    elif(jira_status == "Accepted" or jira_status == "In Progress" or jira_status == "In Review" or jira_status == "Reopened"):
        idev += 1
        report_table_dev += row
    elif(jira_status == "Resolved"):
        iqa += 1
        report_table_qa += row
    elif(jira_status == "Feedback"):
        iinput += 1
        report_table_input += row

report_table_new+="""</table>"""
report_table_dev+="""</table>"""
report_table_qa+="""</table>"""
report_table_input+="""</table>"""


html_report_file = "jiras.html"
html_file = open(html_report_file,"w")
if(report_table_new.find('<td>') != -1):
    html_title = """<h3><font color=%s>Unaccepted JIRAs:- Count: %s</font></h3><br/>""" % ("green", inew)
    html_file.write(html_title)
    html_file.write(report_table_new)
    html_file.write("<br/><br/>")
if(report_table_input.find('<td>') != -1):
    html_title = """<h3><font color=%s>JIRAs in Feedback state:- Count: %s</font></h3><br/>""" % ("green", iinput)
    html_file.write(html_title)
    html_file.write(report_table_input)
    html_file.write("<br/><br/>")
if(report_table_dev.find('<td>') != -1):
    html_title = """<h3><font color=%s>Accepted JIRAs:- Count: %s</font></h3><br/>""" % ("green", idev)
    html_file.write(html_title)
    html_file.write(report_table_dev)
    html_file.write("<br/><br/>")
if(report_table_qa.find('<td>') != -1):
    html_title = """<h3><font color=%s>JIRAs to verify by QA team:- Count: %s</font></h3><br/>""" % ("green", iqa)
    html_file.write(html_title)
    html_file.write(report_table_qa)
    html_file.write("<br/><br/>")
html_file.close()

