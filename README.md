All hidden yaml files to be escorted out of the building by security at the appropriate time

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


## Prerequisites

- [Multipass](https://multipass.run/)

- [Git, or any other Git client](https://git-scm.com/)

- It also doesn't hurt to have [kubectl](https://kubernetes.io/docs/reference/kubectl/) installed on your host machine, though the Linux VM bootstraps with it installed and aliased to `k` so it's not really necessary.

## Getting started

#### From your host machine

`multipass launch -n <vm name> -m 4G -c 2 -d 10GB --cloud-init cloud-init/packages.yaml`

`multipass shell <nm name>`

#### From the VM

Run bootstrap.sh to clone the repository:

`./bootstrap.sh`

Run the install scripts (as sudo):

`cd boundary-bootstrap/cloud-init/scripts && sudo ./install.sh`

#### Using Boundary

The URL is `https://<VM IP>:9200`

Username and password are printed after the install script runs and can be found in `database_login_role_info.txt` under `Initial auth information`.

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


## Troubleshooting

#### Multipass not deleting machine after delete & purge

`multipass stop`

`multipass list`

`multipass delete <vm name> --purge`

`multipass list`

