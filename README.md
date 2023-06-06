# Boundary on Multipass

## What is Boundary?

[What is Boundary?](https://developer.hashicorp.com/boundary/docs/overview/what-is-boundary)

Boundary is a [Zero-Trust](https://en.wikipedia.org/wiki/Zero_trust_security_model), identity-based session broker. It provides secure, identity and role-based access for infrastructure and services. 

This repo is a quickstart to getting up and running with Boundary using Multipass to run its host VM, and K3s to run a lightweight Postgres backend.

Running a dev environment with `boundary dev` is ephemeral, has a host of limitations, and not suitable for all development-tier use cases. This guide more closely mirrors a basic production-grade, non-HA deployment.

## Multipass & K3s??

Multipass offers an easy and intuitive command-line interface to an underlying hypervisor, making Virtual Machine orchestration far more simple with less oversight and configuration required. 

K3s provides that VM with a lightweight distribution of Kubernetes, making it less stressful for the VM to run and dealing with much of the configuration you'd normally get bogged down in when setting up a reproduction/demo/dev environment with k8s.

## Prerequisites

- [Multipass](https://multipass.run/)

- [Git, or any other Git client](https://git-scm.com/)

- It also doesn't hurt to have [kubectl](https://kubernetes.io/docs/reference/kubectl/) installed on your host machine, though the Linux VM bootstraps with it installed and aliased to `k` so it's not really necessary.


## Architecture

The architecture is fairly simple:

![Architectural Diagram](https://github.com/conor-mccullough/boundary-bootstrap/raw/main/deployment-diagram.png)

If we were to `tree` this it would look something like this:

- Host OS
    - Multipass
        - VM
            - Boundary Controller
            - Boundary Worker
            - K3s
                - Postgres DB


## Getting started

#### From your host machine

`multipass launch -n <vm name> -m 4G -c 2 -d 10GB --cloud-init cloud-init/packages.yaml`

`multipass shell <nm name>`

#### From the VM

1. Run `bootstrap.sh` to clone the repository, and run the install scripts (as sudo):
`./bootstrap.sh && cd boundary-bootstrap/cloud-init/scripts && sudo ./install.sh`
2. Paste your Boundary Enterprise license at the prompt.
3. `export BOUNDARY_ADDR=https://localhost:9200`
4. Log in with `boundary authenticate` and the username & password printed in output under `auth_method`.
5. You'll likely run into a keyring error when logging in. Run `gpg --full-generate-key`, then run `pass init <user ID from GPG>`, with the user ID being the input provided for the `Real name:` prompt. in the `gpg` command.

#### Using Boundary

The URL is `https://<VM IP>:9200`

Username and password are printed after the install script runs and can be found in `database_login_role_info.json` under `auth_method`.

#### Boundary SSH between Multipass VM's

1. Find your `id_rsa` keyfile for Multipass (on your mac), and copy it to the place you want to SSH from:
`sudo cp /var/root/Library/Application\ Support/multipassd/ssh-keys/id_rsa multipass-key`

2. Validate it works with native SSH:
`ssh -i ~/multipass-key ubuntu@<target VM IP>`

3. Under "Credential Stores", add the `multipass-key` saved previously as a Static credential, then choose the appropriate username (`ubuntu` for native Multipass VM's)
4. Create a target using the "public" (192.168.64.x) address of the machine you wish to SSH to
5. Within that target, add your new Static credential as an Injected Application Credential
6. Test the connection with `boundary connect ssh -target-id=<SSH target ID>`


## Cleanup

`multipass delete <vm name> --purge`

Or to purge all deleted VM's:

`multipass purge`

## Notes

#### `cloud-init` - Order of Operations

[Cloud-init operates in stages](https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/8/html/configuring_and_managing_cloud-init_for_rhel_8/introduction-to-cloud-init_cloud-content#cloud-init-operates-in-stages_introduction-to-cloud-init) - This document outlines it at a very high level. For a more detailed look at the exact stages, refer to [cloud.cfg.tmpl](https://github.com/canonical/cloud-init/blob/main/config/cloud.cfg.tmpl).


## Troubleshooting

#### Log Locations

- `/Library/Logs/Multipass/multipassd.log` - Found on your Mac. Multipass Daemon logs. If your machine crashes before it can launch, you may find details here.

- `/var/log/cloud-init.log` - Found on your VM. `cloud-init` logs. If your machine is launching but not initializing properly, you may find details here.

- `/var/log/syslog` - May contain more details around errors seen in `cloud-init.log` and other actions taken/failed during initialization. 

#### VM Initialization was incomplete - Missing files/packages

Try to identify where exactly the script(s) have failed. For example if `jq` isn't installed, then look through the above files to see whether there is a failure directly related - or which previous commands/actions were successful beforehand.

See [write_files not working for all elements](#write_files-not-working-for-all-elements).

#### Multipass not deleting machine after delete & purge

`multipass stop`

`multipass list`

`multipass delete <vm name> --purge`

`multipass list`

#### Known Issues

These are mostly incredibly trivial things I haven't made time to fix yet.

##### `kubectl` doesn't work

This is a simple fix. The Ubuntu user profile needs playing around with. Until this is done all kube commands can be executed with `sudo`.

##### `write_files` not working for all elements

You may need to include a `defer: true` line in the related `write_files` block - this will tell cloud-init to wait until the "final" stage to perform the write action, after all users are created and packages installed.

Also take note of the previously mentioned order of operations.
