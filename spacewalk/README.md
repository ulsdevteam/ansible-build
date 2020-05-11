The spacewalkclientOEL.yml playbook is intended to be run on new server builds to install the Spacewalk client, to make sure RHN is up to date and to register and activate the new system with the Spacewalk server.

activationkey.yml is referenced in the main playbook and contains the organization specific activation key for Spacewalk.

rhn_check.yml is intended as a quick way to get clients to communicate back to Spacewalk server.  For instance, if you scheduled software updates to a number of systems you can run this playbook to get them to start the process immediately.

This will be referenced in documentation for deploying new servers. 


