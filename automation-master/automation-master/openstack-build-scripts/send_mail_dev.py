#!/usr/bin/python
# -*- coding: utf-8 -*-
import smtplib
import sys
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEBase import MIMEBase
from email import Encoders
import pdb

#pdb.set_trace()

build_status = sys.argv[1]
build_version = sys.argv[2]
fromaddr = 'trilio.build@gmail.com'
toaddrs  = sys.argv[3]

username = 'trilio.build@trilio.io'
password = '52T8FVYZJse'

'''
result_table = """ <table style="width:100%" border="1">
  <tr>
    <b><th>TestName</th>
    <th>Result</th> </b>
  </tr>
"""

test_result_file = "test_results"
with open(test_result_file, "r") as f:
    for line in f:
        row=line.split()
        test_name=str(row[0])
        if (row[1] == "FAILED") :
            text_color = "red"
        else :
            text_color = "green"
        result_table+="""<tr>
          <td><font color="%s">%s</font></td>
          <td><a><font color="%s">%s</font></a></td>
          </tr> """ % (text_color, row[0], text_color, row[1])
result_table+="""</table>"""

html_report_file="results.html"
html_file= open(html_report_file,"w")
html_file.write(result_table)
html_file.close()
'''

if build_status == "0" :
   google_drive_id=sys.argv[4]
   dev_name=sys.argv[5]
   BUILD_BASE_URL="https://drive.google.com/open?id="
   BUILD_URL=BUILD_BASE_URL + google_drive_id
   msg = """From: TrilioVault Build <trilio.build@gmail.com>
To: %s <%s>
MIME-Version: 1.0
Content-type: text/html
Subject: Build - %s
Hello,

</br>
<br>Here is the latest build %s available:
</br> <a href=%s> %s </a>

""" % (dev_name, toaddrs, build_version, build_version, BUILD_URL, BUILD_URL)
   try:
     server = smtplib.SMTP('smtp.gmail.com:587')
     server.ehlo()
     server.starttls()
     server.login(username,password)
     server.sendmail(fromaddr, toaddrs, msg)
     server.quit()
     print "Sent Email"
   except smtplib.SMTPException:
     print "Error: unable to send email"
else:
   msg = MIMEMultipart()
   msg['Subject'] = "Build Failed - %s" % (build_version)
   msg['From'] = fromaddr
   msg['To'] = toaddrs
   part = MIMEBase('application', "octet-stream")
   part.set_payload(open("validate-build.log", "rb").read())
   Encoders.encode_base64(part)
   part.add_header('Content-Disposition', 'attachment; filename="build.log"')
   msg.attach(part)
   msg.attach(MIMEText(email_body, 'html'))
   try:
     server = smtplib.SMTP('smtp.gmail.com:587')
     server.ehlo()
     server.starttls()
     server.login(username,password)
     server.sendmail(fromaddr, toaddrs, msg.as_string())
     server.quit()
     print "Sent Email"
   except smtplib.SMTPException as e:
     print str(e)
     print "Error: unable to send email"
