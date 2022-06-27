#!/bin/bash
set -e

CONFIG_VOLUME=/conf

SERVER_DIRECTORY=/opt/plasticscm5/server
plasticd=$SERVER_DIRECTORY/plasticd
umtool="$plasticd umtool"

# Coloured labels
OK='\033[1;32mOK\033[0m'
WARN='\033[1;33m!!\033[0m'
ERR='\033[1;31m!!\033[0m'

MISS='\033[1;33mMISS\033[0m'

SYNC='\033[1;32mSYNC\033[0m'
MOVE='\033[1;36mMOVE\033[0m'
MOVEARROW='\033[1;36m<-\033[0m'
LINK='\033[1;32mLINK\033[0m'
LINKARROW='\033[1;32m->\033[0m'

# Bold & Clear
B='\033[1;37m'
NC='\033[0m'

function print_help() {    
    echo "plastic.sh is a setup script for this docker container."
    echo -e "Usage:\n\tplastic.sh [-v -q -h] [COMMAND]"
    echo -e "\nAvailable commands:"
    echo -e "\tconfig    Configures the server"
    echo -e "\tstart     Starts a configured server (Default)"
    echo -e "\tfull      Configures and immediately starts the server"
    echo -e "\tsync      Syncs the configurations files after/during a run server"
    echo -e "\thelp      Print this help"
    echo -e "\nAvailable flags:"
    echo -e "\t     --no-admin   Don't create admin user and group during config"
    echo -e "\t-q | --quiet      Turn off output"
    echo -e "\t-v | --verbose    Enable verbose output"
    echo -e "\t-h | --help       Print this help and exit"
}

# Command argument parsing
while test $# -gt 0
do
    case "$1" in
    --no-admin)
        NO_ADMIN=true
        ;;
    -q | --quiet)
        QUIET=true
        ;;
    -v | --verbose)
        VERBOSE=true
        ;;
    -h | --help)
        print_help
        exit 0
        ;;
    --* | -*)
        echo "Unknown argument $1"
        print_help
        exit 1
        ;;
    *)
        if [ -v COMMAND ]; then
            echo "Too many commands: $1"
            print_help
            exit 1
        fi
        COMMAND=$1
        ;;
    esac
    shift
done

# Default command is starting a configured server
# Plasticscm will throw an error if the server is not configured
COMMAND=${COMMAND:-start}

# Main call that is executed at the end of the script
function main() {
    case $COMMAND in
        full)
            (cd $SERVER_DIRECTORY && exec $plasticd configure)
            setup_config
            (cd $SERVER_DIRECTORY && exec $plasticd --console)
            ;;            
        start)
            link_config
            (cd $SERVER_DIRECTORY && exec $plasticd --console)
            ;;        
        config)
            (cd $SERVER_DIRECTORY && exec $plasticd configure)
            setup_config
            ;;            
        sync)
            sync_config
            ;;
        help)
            print_help
            exit 0
            ;;
        *)
            echo "Unknown command $COMMAND"
            print_help
            exit 1
            ;;
    esac
}

function setup_config {
    declare -a files=("jet.conf"
                      "users.conf"
                      "groups.conf"
                      "server.conf"
                      "network.conf"
                      #"lock.conf"
                      #"cryptedservers.conf"
                      "webadmin.conf"
                      #"loader.log.conf"
                      )

    [ ! $QUIET ] && echo ""
    [ ! $QUIET ] && echo "Setting up configuration files and linking."
    [ ! $QUIET ] && echo -e "$CONFIG_VOLUME/ $LINKARROW $SERVER_DIRECTORY/"
    
    [ ! $QUIET ] && echo -e "${B}CONFIGURATIONS:${NC}"                  
    for f in "${files[@]}"
    do
        [ ! $QUIET ] && echo -e "$OK   $f"        
        if [ ! -f "$CONFIG_VOLUME/$f" ]; then
        # If no file comes preconfigured in /conf
            [ ! $QUIET ] && echo -e -n "     $MISS Not provided by $CONFIG_VOLUME/. "
            # Check if the server offers a preconfigured file
            if [ -f "$SERVER_DIRECTORY/$f" ] ; then
                [ ! $QUIET ] && echo "Found existing $f in server."
                mv "$SERVER_DIRECTORY/$f" "$CONFIG_VOLUME/$f"
                [[ ! $QUIET && $VERBOSE ]] && echo -e "     $MOVE $CONFIG_VOLUME/$f $MOVEARROW $SERVER_DIRECTORY/$f"                
            else
            # Create a new file otherwise
                [ ! $QUIET ] && echo "Creating new file in $CONFIG_VOLUME/."
                touch "$CONFIG_VOLUME/$f"
            fi
            ln -s "$CONFIG_VOLUME/$f" $SERVER_DIRECTORY
            [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/$f $LINKARROW $SERVER_DIRECTORY/$f"                    
        else
        # If files comes preconfigured in /conf
            # Check if a file already exists in the server for some reason
            if [ -f "$SERVER_DIRECTORY/$f" ] ;  then
                [ ! $QUIET ] && echo -e "     $WARN File already existing in server. Renaming as .bak"
                mv "$SERVER_DIRECTORY/$f" "$SERVER_DIRECTORY/$f.bak"
            fi
            ln -s "$CONFIG_VOLUME/$f" $SERVER_DIRECTORY
            [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/$f $LINKARROW $SERVER_DIRECTORY/$f"                      
        fi        
    done
    
    [ ! $QUIET ] && echo -e "\n${B}LICENSE:${NC}"
    if [ -f "$CONFIG_VOLUME/plasticd.lic" ]; then
        [ ! $QUIET ] && echo -e "$OK   plasticd.lic"
        [ ! $QUIET ] && echo "     License file found in $CONFIG_VOLUME/."
        if [ -f "$SERVER_DIRECTORY/plasticd.lic" ] ; then
            [ ! $QUIET ] && echo -e "     Temporary license existing in server. Renaming as .bak"
            mv "$SERVER_DIRECTORY/plasticd.lic" "$SERVER_DIRECTORY/plasticd.lic.bak"
        fi
        ln -s "$CONFIG_VOLUME/plasticd.lic" $SERVER_DIRECTORY
        [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/plasticd.lic $LINKARROW $SERVER_DIRECTORY/plasticd.lic"
    elif [ -f "$SERVER_DIRECTORY/plasticd.lic" ] ; then
        [ ! $QUIET ] && echo -e "$OK   plasticd.lic"
        [ ! $QUIET ] && echo "     License file found in the server."
        mv "$SERVER_DIRECTORY/plasticd.lic" "$CONFIG_VOLUME/plasticd.lic"
        [[ ! $QUIET && $VERBOSE ]] && echo -e "     $MOVE $CONFIG_VOLUME/plasticd.lic $MOVEARROW $SERVER_DIRECTORY/plasticd.lic"
        ln -s "$CONFIG_VOLUME/plasticd.lic" $SERVER_DIRECTORY
        [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/plasticd.lic $LINKARROW $SERVER_DIRECTORY/plasticd.lic"
    else
        [ ! $QUIET ] && echo -e "$ERR   No license file found in either $CONFIG_VOLUME/ or the server. Something went wrong."
        exit 2
    fi
    
    # Add admin user and group
    if [ ! $NO_ADMIN ] ; then
        [ ! $QUIET ] && echo -e "\nCreating default users & groups."
        [ ! $QUIET ] && echo -e "\n${B}USERS:${NC}"
        $umtool createuser admin plastic_admin > /dev/null || true
        [ ! $QUIET ] && echo -e "admin (pw: plastic_admin)"
        
        [ ! $QUIET ] && echo -e "\n${B}GROUPS:${NC}"
        $umtool creategroup admins > /dev/null || true
        [ ! $QUIET ] && echo -e -n "admins:"
        $umtool addusertogroup admin admins > /dev/null || true
        [ ! $QUIET ] && echo -e " admin"
    fi
    
    [ ! $QUIET ] && echo "Done."    
}

function link_config {
    declare -a files=("jet.conf"
                      "users.conf"
                      "groups.conf"
                      "server.conf"
                      "network.conf"
                      "lock.conf"
                      "cryptedservers.conf"
                      "webadmin.conf"
                      "loader.log.conf"
                      )

    [ ! $QUIET ] && echo ""
    [ ! $QUIET ] && echo "Linking configurations for configured server."
    [ ! $QUIET ] && echo -e "$CONFIG_VOLUME/ $LINKARROW $SERVER_DIRECTORY/"
    
    [ ! $QUIET ] && echo -e "${B}CONFIGURATIONS:${NC}"
    for f in "${files[@]}"
    do
        if [ -f "$CONFIG_VOLUME/$f" ] ; then      
            [ ! $QUIET ] && echo -e "$OK   $f"
            # Check if we are already linked for some reason
            if [ -L "$SERVER_DIRECTORY/$f" ] ; then
                [ ! $QUIET ] && echo -e "     $WARN Already linked to server. (This should not happen)"            
            else
            # Check if a file already exists in the server for some reason
                if [ -f "$SERVER_DIRECTORY/$f" ] ;  then
                    [ ! $QUIET ] && echo -e "     $WARN File already existing in server. Renaming as .bak"
                    mv "$SERVER_DIRECTORY/$f" "$SERVER_DIRECTORY/$f.bak"
                fi
                ln -s "$CONFIG_VOLUME/$f" $SERVER_DIRECTORY
                [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/$f $LINKARROW $SERVER_DIRECTORY/$f"
            fi
        else
            [ ! $QUIET ] && echo -e "$MISS $f"
        fi
    done
    
    [ ! $QUIET ] && echo -e "\n${B}LICENSE:${NC}"
    if [ -f "$CONFIG_VOLUME/plasticd.lic" ] ; then        
        [ ! $QUIET ] && echo -e "$OK   plasticd.lic"
        ln -s -f "$CONFIG_VOLUME/plasticd.lic" $SERVER_DIRECTORY
        [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/plasticd.lic $LINKARROW $SERVER_DIRECTORY/plasticd.lic"
    else
        [ ! $QUIET ] && echo -e "$ERR   plasticd.lic"
        [ ! $QUIET ] && echo -e "$     No license file found in $CONFIG_VOLUME/."
        exit 2
    fi
    if [ -f "$CONFIG_VOLUME/plasticd.token.lic" ] ; then        
        [ ! $QUIET ] && echo -e "$OK   plasticd.token.lic"
        ln -s -f "$CONFIG_VOLUME/plasticd.lic" $SERVER_DIRECTORY
        [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/plasticd.lic $LINKARROW $SERVER_DIRECTORY/plasticd.lic"
    else
        [ ! $QUIET ] && echo -e "$MISS plasticd.token.lic"
    fi
    
    [ ! $QUIET ] && echo "Done."
}

function sync_config {
    declare -a files=("jet.conf"
                      "users.conf"
                      "groups.conf"
                      "server.conf"
                      "network.conf"
                      "lock.conf"
                      "cryptedservers.conf"
                      "webadmin.conf"
                      "loader.log.conf"                      
                      )
    
    declare -a license=("plasticd.lic"
                        "plasticd.token.lic"
                        )
      
    [ ! $QUIET ] && echo "Syncing all configurations between server and $CONFIG_VOLUME/."
    
    [ ! $QUIET ] && echo -e "${B}CONFIGURATIONS:${NC}"          
    for f in "${files[@]}"
    do
        if [ -f "$CONFIG_VOLUME/$f" ] ; then
            if [ -L "$SERVER_DIRECTORY/$f" ] ; then
                [ ! $QUIET ] && echo -e "$OK   $f"
                [[ ! $QUIET && $VERBOSE ]] && echo "     File already exists in $CONFIG_VOLUME/."
            else
                [ ! $QUIET ] && echo -e "$ERR   $f"
                [ ! $QUIET ] && echo "     File exists in $CONFIG_VOLUME/ but not on the server."
            fi
        else
            if [ -f "$SERVER_DIRECTORY/$f" ] ; then
                [ ! $QUIET ] && echo -e "$SYNC $f"
                [[ ! $QUIET && $VERBOSE ]] && echo -e "     $MOVE $CONFIG_VOLUME/$f $MOVEARROW $SERVER_DIRECTORY/$f"
                mv "$SERVER_DIRECTORY/$f" "$CONFIG_VOLUME/$f"
                [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/$f $LINKARROW $SERVER_DIRECTORY/$f"
                ln -s "$CONFIG_VOLUME/$f" $SERVER_DIRECTORY
            else
                [ ! $QUIET ] && echo -e "$MISS $f"
            fi
        fi
    done
    
    [ ! $QUIET ] && echo -e "\n${B}LICENSE:${NC}"
    for f in "${license[@]}"
    do
        if [ -f "$CONFIG_VOLUME/$f" ] ; then        
            [ ! $QUIET ] && echo -e "$OK   $f"
        else
            if [ -f "$SERVER_DIRECTORY/$f" ] ; then
                [ ! $QUIET ] && echo -e "$SYNC $f"
                [[ ! $QUIET && $VERBOSE ]] && echo -e "     $MOVE $CONFIG_VOLUME/$f $MOVEARROW $SERVER_DIRECTORY/$f"
                mv "$SERVER_DIRECTORY/$f" "$CONFIG_VOLUME/$f"
                [[ ! $QUIET && $VERBOSE ]] && echo -e "     $LINK $CONFIG_VOLUME/$f $LINKARROW $SERVER_DIRECTORY/$f"
                ln -s "$CONFIG_VOLUME/$f" $SERVER_DIRECTORY
            else
                [ ! $QUIET ] && echo -e "$MISS $f"
            fi
        fi
    done
    
    [ ! $QUIET ] && echo "Done."
}

main "$@"; exit

