#!/bin/bash

# Exit immediately if a command returns a non-zero status
set -e
# shellcheck disable=SC1091
source ./dynamic-zone-parameter.sh

function add-dynamic-zone-template() {

	# master zone template
	# rndc addzone exampleb.xx in internal  '{type master; file "master/example.aa"; allow-update{ key "proxy-key";};};'

	echo "# ACTION create directory $ZONE_MASTER_TEMPLATE_DIRECTORY"
	mkdir -p "$BIND_CHROOT$ZONE_MASTER_TEMPLATE_DIRECTORY"

	ZONE_MASTER_TEMPLATE="$ZONE_MASTER_TEMPLATE_DIRECTORY/template.zone"

	echo "# ACTION touch $BIND_CHROOT$ZONE_MASTER_TEMPLATE"
	touch "$BIND_CHROOT$ZONE_MASTER_TEMPLATE"

	# change user
	chown bind:bind "$BIND_CHROOT/$ZONE_MASTER_TEMPLATE"

	# change file attribute
	chmod 0666 "$BIND_CHROOT/$ZONE_MASTER_TEMPLATE"

	# TODO detect chroot

	echo "# ACTION  create master zone template"
	cat <<EOF >"$BIND_CHROOT/$ZONE_MASTER_TEMPLATE"
; $ZONE_MASTER_ZONE
\$TTL    604800
@       IN      SOA     ns1.$ZONE_MASTER_ZONE. root.$ZONE_MASTER_ZONE. (
                     2006020201 ; Serial
                         604800 ; Refresh
                          86400 ; Retry
                        2419200 ; Expire
                         604800); Negative Cache TTL
;
@				NS	ns.$ZONE_MASTER_ZONE.
ns                     A       127.0.0.1
;END OF ZONE FILE
EOF

}

function add-dynamic-zone() {

	# set script name
	TMP_ADDZONE_SCRIPT="/tmp/addzone.sh"

	echo "# ACTION write addzone script"

	cat <<EOF >"$TMP_ADDZONE_SCRIPT"
#!/bin/bash
rndc addzone $DYNAMIC_ADD_ZONE '{type master; file "master/template.zone"; update-policy{ grant "$DDNS_KEY_NAME" zonesub ANY;};};'
EOF

	echo "# ACTION addzone script set file attribute  execute"
	chmod +x $TMP_ADDZONE_SCRIPT

	echo "# ACTION addzone via script "
	if ($TMP_ADDZONE_SCRIPT); then
		echo "# INFO addzone successful"
	else
		echo "# ERROR addzone raise a error "
		echo "# EXIT 1"
		exit 1
	fi

	# check template

	if (named-checkzone "$ZONE_MASTER_ZONE" "$BIND_CHROOT/$ZONE_MASTER_TEMPLATE"); then
		echo "# INFO check master template zone OK"
	else
		echo "# ERROR check master template file raise a error"
		echo "# EXIT 1"
		exit 1
	fi

}

# call  function
add-zone-template

# call function
add-dynamic-zone
