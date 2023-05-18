All hidden yaml files to be escorted out of the building by security at the appropriate time

## Architecture

Details of how the repo functions go here

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

