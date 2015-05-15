# dcm4chee4-vagrant
A **[Vagrant](https://www.vagrantup.com/)** VM profile/configuration to quickly spin up an instance of **[DCM4CHEE v4](https://github.com/dcm4che/dcm4chee-arc-cdi)**

---

## What it will do
- Spin up an Ubuntu 14.04 LTS virtual machine with 1GB RAM
- Use aptitude to install GIT Client, OpenJDK 7, Apache Maven 3, and Postgresql 9.4
- Download and install **[Wildfly](http://wildfly.org/)** 8.2
- Download and compile all the DCM4CHEE sources from github
- Deploy and configure DCM4CHEE and all of its dependepncies into Wildfly

## Usage
- Download and install VirtualBox and Vagrant
- Clone this project and cd into the directory
- Run `vagrant up`
- Within minutes you should have a VM up and running with DCM4CHEE v4

## Contributors
- Mohannad Hussain @mohannadhussain

## License
MIT License
