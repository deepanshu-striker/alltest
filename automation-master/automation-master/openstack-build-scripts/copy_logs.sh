#!/usr/bin/expect

set IP [lindex $argv 0]
set PWD [lindex $argv 1]
set SRC_PATH [lindex $argv 2]
set DST_PATH [lindex $argv 3]

pwd
spawn rsync -avz root@$IP:$SRC_PATH $DST_PATH

while {1} {
  expect {

    eof                          {break}
    "Are you sure you want to continue connecting"   {send "yes\r"}
    "password:"                  {send "$PWD\r"}
    "Password:"                  {send "$PWD\r"}
    "*\]"                        {send "exit\r"}
  }
}
wait

