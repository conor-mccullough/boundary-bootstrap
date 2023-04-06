#!/bin/bash
set -x
boundary database init -config /opt/boundary/boundary-controller.hcl > database_login_role_info.txt
