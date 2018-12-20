#!/bin/bash

ssh-keyscan github.com >> /home/stack/.ssh/known_hosts
ssh-keyscan github.com >> /home/tvault-gui/.ssh/known_hosts
