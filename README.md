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

Pull the repo and bootstrap files:
`./bootstrap.sh`

Write the license value into the license file:
`echo '<boundary end license here>' > /home/ubuntu/license.hclic`

Run the install scripts:
`cd boundary-bootstrap/cloud-init/scripts && sudo ./install.sh`

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

