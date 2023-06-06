#!/bin/bash
set -x
boundary database init -format=json -config /opt/boundary/boundary-controller.hcl > database_login_role_info.json
