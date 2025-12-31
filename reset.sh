#!/bin/bash
echo "This will delete your existing database (/home/docker/guacamole_stack/db/data/)"
echo "          delete your recordings        (/home/docker/guacamole_stack/guacd/record/)"
echo "          delete your recordings        (/home/docker/guacamole_stack/guacamole/record/)"
echo "          delete your drive files       (/home/docker/guacamole_stack/guacd/drive/)"
echo "          delete your drive files       (/home/docker/guacamole_stack/guacamole/drive/)"
echo ""
read -p "Are you sure? [y/n]" -n 1 -r
echo ""                         # (optional) move to a new line
if [[ $REPLY =~ ^[Yy]$ ]]; then # do dangerous stuff
	sudo rm -vrf /home/docker/guacamole_stack
	docker rm -f
else
	echo "Aborting"
fi
