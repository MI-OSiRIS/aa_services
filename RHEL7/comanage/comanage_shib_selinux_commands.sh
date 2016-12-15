# selinux ... allow the web server to serve comanage-registry..

# for comanage registry
semanage fcontext -a -t httpd_sys_content_t "/srv/comanage/.*"
restorecon -Rv /srv/comanage

# you will have to run this every time you upgrade.
semanage fcontext -a -t httpd_sys_rw_content_t "/srv/comanage/comanage-registry-1.0.5/local/tmp(/.*)?"
restorecon -Rv /srv/comanage/comanage-registry-1.0.5/local/tmp

# for shibboleth
semanage fcontext -a -t httpd_sys_rw_content_t "/var/cache/shibboleth(/.*)?"
restorecon -Rv /var/cache/shibboleth

semanage fcontext -a -f s -t httpd_var_run_t /var/run/shibboleth/shibd.sock
restorecon -Rv /var/run/shibboleth/shibd.sock