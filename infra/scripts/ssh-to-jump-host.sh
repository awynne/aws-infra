#!/bin/bash

cd terraform && eval $(terraform output -raw ssh_command_direct)
