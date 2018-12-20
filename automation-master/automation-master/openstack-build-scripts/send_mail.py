#!/usr/bin/python
# -*- coding: utf-8 -*-
import smtplib
import sys
from email.MIMEMultipart import MIMEMultipart
from email.MIMEText import MIMEText
from email.MIMEBase import MIMEBase
from email import Encoders
import os
import os.path

build_status = sys.argv[1]
build_version = sys.argv[2]
fromaddr = 'trilio.build@trilio.io'
toaddrs = sys.argv[4]
tolist = toaddrs.split(",")
commaspace = ", "
join_toaddr = commaspace.join(tolist)
build_size = os.environ["build_tar_size"]
compressed = False

if build_size < "2":
    compressed = True

username = 'trilio.build@trilio.io'
password = '52T8FVYZJse'

changelog_html = "../monitoring-scripts/build_changeset.html"
changelog_table = ""

if (os.path.exists(changelog_html)):
    with open(changelog_html, "r") as f:
        for line in f:
            changelog_table += line


def send_mail(subject, build_version):
    msg = MIMEMultipart()
    msg['Subject'] = str(subject) + " - " + str(build_version)
    msg['From'] = fromaddr
    msg['To'] = join_toaddr
    part = MIMEBase('application', "octet-stream")
    #part.set_payload(open("validate-build.log", "rb").read())
    Encoders.encode_base64(part)
    #part.add_header('Content-Disposition', 'attachment; filename="build.log"')
    #msg.attach(part)
    #email_body = """
    #<h3>Test Results:</h3>
    #<dev> %s </dev>
    #""" % (result_table)
    #msg.attach(MIMEText(email_body, 'html'))
    try:
        server = smtplib.SMTP('smtp.gmail.com:587')
        server.ehlo()
        server.starttls()
        server.login(username, password)
        server.sendmail(fromaddr, tolist, msg.as_string())
        server.quit()
        print "Sent Email"
    except smtplib.SMTPException as e:
        print str(e)
        print "Error: unable to send email"


if build_status == "0":
    google_drive_id = sys.argv[3]
    BUILD_BASE_URL = "https://drive.google.com/open?id="
    BUILD_URL = BUILD_BASE_URL + google_drive_id
    if compressed:
        print "build is compressed."
        msg = """From: TrilioVault Build <trilio.build@trilio.io>
To: %s
MIME-Version: 1.0
Content-type: text/html
Subject: Compressed Build - %s
Hello Team,

</br>
<br><br>Here is the latest Compressed build %s available of size %s : </br></br>
<br><br><a href=%s> %s </a></br></br>
%s
""" % (join_toaddr, build_version, build_version, build_size, BUILD_URL, BUILD_URL, changelog_table)
    else:
        print "build is not compressed."
        msg = """From: TrilioVault Build <trilio.build@trilio.io>
To: %s
MIME-Version: 1.0
Content-type: text/html
Subject: Build - %s
Hello Team,

</br>
<br><br>Here is the latest build %s available of size %s : </br></br>
<br><br><a href=%s> %s </a></br></br>
%s
""" % (join_toaddr, build_version, build_version, build_size, BUILD_URL, BUILD_URL, changelog_table)
    try:
        server = smtplib.SMTP('smtp.gmail.com:587')
        server.ehlo()
        server.starttls()
        server.login(username, password)
        server.sendmail(fromaddr, tolist, msg)
        server.quit()
        print "Sent Email"
    except smtplib.SMTPException:
        print "Error: unable to send email"

elif build_status == "1":
    send_mail("Build Failed", build_version)

elif build_status == "2":
    send_mail("Build Compression Failed", build_version)

else:
    google_drive_id = sys.argv[3]
    BUILD_BASE_URL = "https://drive.google.com/open?id="
    BUILD_URL = BUILD_BASE_URL + google_drive_id
    msg = """From: TrilioVault Build <trilio.build@trilio.io>
To: TrilioData <engineering@trilio.io>
MIME-Version: 1.0
Content-type: text/html
Subject: Build - %s
Hello Team,

</br>
<br>Here is the latest build %s available of size %s:
</br> <a href=%s> %s </a>

""" % (build_version, build_version, build_size, BUILD_URL, BUILD_URL)
    try:
        server = smtplib.SMTP('smtp.gmail.com:587')
        server.ehlo()
        server.starttls()
        server.login(username, password)
        server.sendmail(fromaddr, tolist, msg)
        server.quit()
        print "Sent Email"
    except smtplib.SMTPException as e:
        print str(e)
        print "Error: unable to send email"
