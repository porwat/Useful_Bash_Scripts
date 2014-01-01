#!/bin/bash

update_count=$(yum check-update | egrep "(.i386|.x86_64|.noarch|.src)" | wc -l)

echo "Updates available:" $update_count


