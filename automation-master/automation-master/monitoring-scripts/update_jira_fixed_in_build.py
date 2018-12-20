#!/bin/python
# -*- coding: utf-8 -*-

from jira import JIRA
import sys
import json
import datetime
import config

fixed_in_build = sys.argv[1]
build_changelog = "build_changeset.html"

username = config.JIRA_USERNAME
pwd = config.JIRA_PASSWD
url = config.JIRA_URL

options = {'server': url}
jira = JIRA(options,basic_auth=(username, pwd))

jira_list = []
jira_txt = "TVAULT-"

with open(build_changelog) as f:
    for line in f:
        if((line.lower()).find(jira_txt.lower()) != -1):
            line = line.lstrip()
            tmp = line[(line.lower()).find(jira_txt.lower()):]
            tmp = (tmp.lower()).replace(jira_txt.lower(),'')
            for i in range(0,len(tmp)):
                if(tmp[i].isdigit() == False and tmp[0].isdigit() == True):
                    id = tmp[:i]
                    break
            jira_list.append(jira_txt+str(id))
jira_ids = list(set(jira_list))
print jira_ids

for jiraid in jira_ids:
    new_data = []
    existing_data = []
    i = jira.search_issues("id="+str(jiraid), json_result=True)['issues'][0]
    if(i['fields']['customfield_10101'] != None):
        for b in i['fields']['customfield_10101']:
            existing_data.append(b)
    existing_data.append(fixed_in_build)
    new_data = list(set(existing_data))
    for issue in jira.search_issues('id='+str(jiraid)):
        issue.update(fields={'customfield_10101': new_data})
