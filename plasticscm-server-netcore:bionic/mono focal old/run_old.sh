#!/bin/bash
set -e

SERVER_DIRECTORY=/opt/plasticscm5/server

OK='\033[1;32mOK\033[0m'
WARN='\033[1;33m!!\033[0m'
ERR='\033[1;31m!!\033[0m'

MISS='\033[1;33mMISS\033[0m'

B='\033[1;37m'
NC='\033[0m'

function setup_config {
    declare -a files=("jet.conf"
                      "user.conf"
                      "groups.conf"
                      "server.conf"
                      "network.conf"
                      #"lock.conf"
                      #"cryptedservers.conf"
                      "webadmin.conf"
                      #"loader.log.conf"
                      )
    #/conf/plasticd.token.lic

    echo "Setting up configuration files."
    echo -e "${B}CONFIGURATIONS:${NC}" 
    for f in "${files[@]}"
    do
        echo $f
    done
    echo "--------------------"
                   
    for f in "${files[@]}"
    do
        echo -e "$B$f:$NC"
        # If no file comes preconfigured in /conf
        if [ ! -f "/conf/$f" ]; then
            echo -e "$MISS Not provided by /conf."
            # Check if the server offers a preconfigured file
            if [ -f "$SERVER_DIRECTORY/$f" ] ; then
                echo "     Found existing $f in server. Copying to /conf and linking back to server..."
                mv "$SERVER_DIRECTORY/$f" "/conf/$f"
            else
            # Create a new file otherwise
                echo "     Creating new file in /conf and linking to server..."
                touch "/conf/$f"
            fi
            ln -s "/conf/$f" $SERVER_DIRECTORY            
        else
        # If files comes preconfigured in /conf
            # Check if a file already exists in the server for some reason
            if [ -f "$SERVER_DIRECTORY/$f" ] ;  then
                echo -e "$WARN   File already existing in server. Renaming as .bak..."
                mv "$SERVER_DIRECTORY/$f" "$SERVER_DIRECTORY/$f.bak"
            fi                
            ln -s "/conf/$f" $SERVER_DIRECTORY    
        fi
        echo -e "$OK   Linked."   
    done
    echo ""
    echo -e "${B}LICENSE:${NC}"
    echo -e "${B}plasticd.lic${NC}"
    if [ -f "$SERVER_DIRECTORY/plasticd.lic" ] ; then
        echo -e "$OK  License file found in the server. Copying to /conf and linking back to server..."
        mv "$SERVER_DIRECTORY/plasticd.lic" "/conf/plasticd.lic"
        ln -s "/conf/plasticd.lic" $SERVER_DIRECTORY
    else
        echo -e "$ERR   No license file found in the server. Something went wrong."
        exit 1;
    fi
    echo "Done."    
}

function link_config {
    declare -a files=("jet.conf"
                      "user.conf"
                      "groups.conf"
                      "server.conf"
                      "network.conf"
                      "lock.conf"
                      "cryptedservers.conf"
                      "webadmin.conf"
                      "loader.log.conf"
                      )
    #/conf/plasticd.token.lic

    echo "Linking configurations for configured server:"
    echo -e "${B}CONFIGURATIONS:${NC}"
    for f in "${files[@]}"
    do
        if [ -f "/conf/$f" ] ; then        
            echo -e "$OK   $f"
        else
            echo -e "$MISS $f"
        fi
    done
    echo "--------------------"
                   
    for f in "${files[@]}"
    do
        # Link all existing files to the server
        if [ -f "/conf/$f" ] ; then 
            echo -e "$B$f:$NC"
            # Check if we are already linked for some reason
            if [ -L "$SERVER_DIRECTORY/$f" ] ; then
                echo -e "$WARN   Already linked to server. (This should not happen)"            
            else
            # Check if a file already exists in the server for some reason
                if [ -f "$SERVER_DIRECTORY/$f" ] ;  then
                    echo -e "$WARN   File already existing in server. Renaming as .bak..."
                    mv "$SERVER_DIRECTORY/$f" "$SERVER_DIRECTORY/$f.bak"
                fi                
                ln -s "/conf/$f" $SERVER_DIRECTORY
                echo -e "$OK   Linked."
            fi
        fi
    done
    echo ""
    echo -e "${B}LICENSE:${NC}"
    echo -e "${B}plasticd.lic${NC}"
    if [ -f "/conf/plasticd.lic" ] ; then
        ln -s -f "/conf/plasticd.lic" $SERVER_DIRECTORY 
        echo -e "$OK   Linked."
    else
        echo -e "$ERR   No license file found in /conf."
        exit 1
    fi
    echo "Done."
}

SYNC='\033[1;32mSYNC\033[0m'
COPY='\033[1;36mCOPY\033[0m'
COPYARROW='\036[1;32m<-\033[0m'
LINK='\033[1;32mLINK\033[0m'
LINKARROW='\033[1;32m->\033[0m'

function sync_config {
    declare -a files=("jet.conf"
                      "user.conf"
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
      
    echo "Syncing all .conf between server and /conf"
    echo -e "${B}CONFIGURATIONS:${NC}"          
    for f in "${files[@]}"
    do
        if [ -f "/conf/$f" ] ; then        
            echo -e "$OK   $f"
        else
            if [ -f "$SERVER_DIRECTORY/$f" ] ; then
                echo -e "$SYNC $f"
                echo -e "  $COPY /conf/$f $COPYARROW $SERVER_DIRECTORY/$f"
                mv "$SERVER_DIRECTORY/$f" "/conf/$f"
                echo -e "  $LINK /conf/$f $SYNCARROW $SERVER_DIRECTORY/$f"
                ln -s "/conf/$f" $SERVER_DIRECTORY
            else
                echo -e "$MISS $f"
            fi
        fi
    done
    echo ""
    echo -e "${B}LICENSE:${NC}"
    for f in "${license[@]}"
    do
        if [ -f "/conf/$f" ] ; then        
            echo -e "$OK   $f"
        else
            if [ -f "$SERVER_DIRECTORY/$f" ] ; then
                echo -e "$SYNC $f"
                echo -e "  $COPY /conf/$f $COPYARROW $SERVER_DIRECTORY/$f"
                mv "$SERVER_DIRECTORY/$f" "/conf/$f"
                echo -e "  $LINK /conf/$f $SYNCARROW $SERVER_DIRECTORY/$f"
                ln -s "/conf/$f" $SERVER_DIRECTORY
            else
                echo -e "$MISS $f"
            fi
        fi
    done
}


# Add admin user
# NOT available in manual installation ???
#umtool cu admin plastic_admin
#umtool cg admins
#umtool autg admin admins

COMMAND=${1:-configAndStart}

case $COMMAND in
    
    configAndStart)
        /opt/plasticscm5/server/plasticd configure
        setup_config
        /opt/plasticscm5/server/plasticd --console
        ;;
        
    start)
        link_config
        /opt/plasticscm5/server/plasticd --console
        ;;
    
    config)
        /opt/plasticscm5/server/plasticd configure
        setup_config
        ;;
        
    sync)
        sync_config
        ;;
    *)
        echo "Unknown command $COMMAND"
        exit 1
        ;;
esac

