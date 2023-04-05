#!/bin/bash
set -x
boundary database init \
   -skip-auth-method-creation \
   -skip-host-resources-creation \
   -skip-scopes-creation \
   -skip-target-creation \
   -config /opt/boundary/boundary-controller.hcl > database_login_role_info.txt
