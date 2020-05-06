#!/bin/sh
gamedatapath="/home/openttd/.openttd"
savepath="/home/openttd/.openttd/save"
savegame="${savepath}/${savename}"
LOADGAME_CHECK="${loadgame}x"
loadgame=${loadgame:-'false'}

PUID=${PUID:-911}
PGID=${PGID:-911}
PHOME=${PHOME:-"/home/openttd"}
USER=${USER:-"openttd"}
DEBUG=${DEBUG:-2}


if [ ! "$(id -u ${USER})" -eq "$PUID" ]; then usermod -o -u "$PUID" ${USER} ; fi
if [ ! "$(id -g ${USER})" -eq "$PGID" ]; then groupmod -o -g "$PGID" ${USER} ; fi
if [ "$(grep ${USER} /etc/passwd | cut -d':' -f6)" != "${PHOME}" ]; then
        if [ ! -d ${PHOME} ]; then
                mkdir -p ${PHOME}
                chown ${USER}:${USER} ${PHOME}
        fi
        usermod -m -d ${PHOME} ${USER}
fi

echo "
-----------------------------------
GID/UID
-----------------------------------
User uid:    $(id -u ${USER})
User gid:    $(id -g ${USER})
User Home:   $(grep ${USER} /etc/passwd | cut -d':' -f6)
-----------------------------------
"
# Modifies the config based on environment variables (supplied by docker run -e xxx)
sed -i "s/^\(rcon_password\s*=\s*\).*\$/\1${RCONPW:-"rconpw123"}/" ${gamedatapath}/openttd.cfg
sed -i "s/^\(admin_password\s*=\s*\).*\$/\1${ADMINPW:-"adminpw123"}/" ${gamedatapath}/openttd.cfg
sed -i "s/^\(server_name\s*=\s*\).*\$/\1${SERVERNAME:-"_My Docker Server_"}/" ${gamedatapath}/openttd.cfg

# Loads the desired game, or prepare to load it next time server starts up!
if [ ${LOADGAME_CHECK} != "x" ]; then

        case ${loadgame} in
                'true')
                        if [ -f  ${savegame} ]; then
                                echo "We are loading a save game!"
                                echo "Lets load ${savegame}"
                                su -l openttd -c "/usr/games/openttd -D -g ${savegame} -x -d ${DEBUG} > /home/openttd/.openttd/openttd.log 2>&1"
                                exit 0
                        else
                                echo "${savegame} not found..."
                                exit 0
                        fi
                ;;
                'false')
                        echo "Creating a new game."
                        su -l openttd -c "/usr/games/openttd -D -x -d ${DEBUG} > /home/openttd/.openttd/openttd.log 2>&1"
                        exit 0
                ;;
                'last-autosave')

			savegame=${savepath}/autosave/`ls -rt ${savepath}/autosave/ | tail -n1`

			if [ -r ${savegame} ]; then
	                        echo "Loading ${savegame}"
        	                su -l openttd -c "/usr/games/openttd -D -g ${savegame} -x -d ${DEBUG} > /home/openttd/.openttd/openttd.log 2>&1"
                	        exit 0
			else
				echo "${savegame} not found..."
				exit 1
			fi
                ;;
                'exit')

			savegame="${savepath}/autosave/exit.sav"

			if [ -r ${savegame} ]; then
	                        echo "Loading ${savegame}"
        	                su -l openttd -c "/usr/games/openttd -D -g ${savegame} -x -d ${DEBUG}"
                	        exit 0
			else
	                        echo "\$loadgame not found, starting new game"
                                su -l openttd -c "/usr/games/openttd -D -x > /home/openttd/.openttd/openttd.log 2>&1" 
			fi
                ;;
		*)
			echo "ambigous loadgame (\"${loadgame}\") statement inserted."
			exit 1
		;;
        esac
else
	echo "\$loadgame (\"${loadgame}\") not set, starting new game"
        su -l openttd -c "/usr/games/openttd -D -x > /home/openttd/.openttd/openttd.log 2>&1"
        exit 0
fi
