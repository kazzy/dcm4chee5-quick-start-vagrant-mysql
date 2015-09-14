# DCM4CHEE v4 Quick Start Vagrant
A **[Vagrant](https://www.vagrantup.com/)** VM profile/configuration to quickly spin up an instance of **[DCM4CHEE v4](https://github.com/dcm4che/dcm4chee-arc-cdi)**

---

## What it will do
- Spin up an Ubuntu 14.04 LTS virtual machine with 1GB RAM
- Use aptitude to install GIT Client, OpenJDK 7, Apache Maven 3, Postgresql 9.4 and HAProxy
- Download and install **[Wildfly](http://wildfly.org/)** 8.2
- Download and compile all the DCM4CHEE and DCM4CHE sources from github
- Deploy and configure DCM4CHEE and all of its dependepncies into Wildfly

## Usage
- Download and install VirtualBox and Vagrant
- Clone/download this project and cd into the directory
- Run `vagrant up`
- Within minutes you should have a VM up and running with DCM4CHEE v4 (watch the console to confirm when it is done - it may take a while if your Internet connection is slow)
- The machine is accessible at the private IP address: 192.168.33.10
- DCM4CHEE v4 listens on the following ports: 
	- HTTP: 8080
	- DICOM: 11112
	- DICOM-TLS: 2762
	- HL7: 2575
	- HL7-TLS: 12575
- DCM4CHEE's URLs of interest:
	- Web UI is accessible at http://192.168.33.10/dcm4chee-web/
	- QIDO end point: http://192.168.33.10/dcm4chee-arc/qido/, examples: 
		- http://192.168.33.10/dcm4chee-arc/qido/DCM4CHEE/studies/?00100010=Bob
		- http://192.168.33.10/dcm4chee-arc/qido/DCM4CHEE/studies/1.2.3/instances
	- WADO-RS end point (returns DICOM object): http://192.168.33.10/dcm4chee-arc/wado/, example:
		- http://192.168.33.10/dcm4chee-arc/wado/DCM4CHEE/studies/1.2.3/series/1.2.3.1/instances/1.2.3.1.1
	- WADO-URI end point (can return a rendered JPEG): http://192.168.33.10/dcm4chee-arc/wado/, example:
		- http://192.168.33.10/dcm4chee-arc/wado/DCM4CHEE?requestType=WADO&studyUID=1.2.3&seriesUID=1.2.3.1&objectUID=1.2.3.1.1
		
## DICOMweb Resources
- DICOMweb unofficial documentation: http://www.dicomweb.org/
- QIDO-RS: ftp://medical.nema.org/medical/dicom/final/sup166_ft5.pdf
- WADO-RS: ftp://medical.nema.org/medical/dicom/final/sup161_ft.pdf
- STOW-RS: ftp://medical.nema.org/medical/dicom/Final/sup163_ft3.pdf

## Contributors
- Mohannad Hussain @mohannadhussain

## Questions? Problems?
Please message me, or enter an issue into the bug tracker.

## License
MIT License
