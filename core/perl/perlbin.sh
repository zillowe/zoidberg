# Set path to perl scriptdirs if they exist
# Parlex Linux keeps perl scripts in /usr/bin/{core,vendor,site}_perl
# Added /usr/bin/*_perl dirs for scripts

[ -d /usr/bin/site_perl ] && append_path '/usr/bin/site_perl'

[ -d /usr/bin/vendor_perl ] && append_path '/usr/bin/vendor_perl'

[ -d /usr/bin/core_perl ] && append_path '/usr/bin/core_perl'

export PATH

# If you have modules in non-standard directories you can add them here.
#export PERLLIB=dir1:dir2

