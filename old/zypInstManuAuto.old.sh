#!/bin/bash

# USAGE:
#       sudo cat /var/log/zypp/history | ./zypInstManuAuto 


TMP_DIR=$(mktemp -d /dev/shm/zypinstma-XXXXXX)
RESULT_DIR=$TMP_DIR/results
mkdir -p $RESULT_DIR
echo "Temp dir $TMP_DIR"
echo ""

function parseZypperCmd()   # NOTE every parameter is 'xxxx' single-quoter quoted
{
    local full_shellcmd="$@"
    
    shift  # 'zypper'
    
    while [[ "${1:0:2}" == "'-" ]]
    do
#         echo "shift $1"
        shift
    done
    
#     echo "$1"
    if [[ "$1" == "'up'" || "$1" == "'update'" ]]; then
        echo "update"
    elif [[ "$1" == "'in'" || "$1" == "'install'" ]]; then
        echo "install"
    elif [[ "$1" == "'rm'" || "$1" == "'remote'" ]]; then
        echo "remove"
    elif [[ "$1" == "'dup'" || "$1" == "'dist-upgrade'" ]]; then
        echo "dist-upgrade"
    elif [[ "$1" == "'purge-kernels'" ]]; then
        echo "purge-kernels"
        
    else
        echo "FAIL"
        return 3
    fi
}

cd $TMP_DIR
touch  installed.txt   installed_user-choose.txt   installed_auto-select.txt   installed_unsure.txt 
function isPackageAlreadyAdded() {
    local package="$1"
    
    local package_="$( echo "$package" | sed 's/\./\\\./g' | sed 's/+/\\+/g'  )"
    if (  cat installed.txt | grep -P "^$package_\t"  >/dev/null 2>&1  ); then
        return 0
    else
        return 1
    fi
}
function removePackage() {
    local package="$1"
    
    sed -i "/^${package}\t/d" installed.txt   installed_user-choose.txt   installed_auto-select.txt   installed_unsure.txt 
}
function addPackage() { 
    local package="$1"
    
    local newLineText="$(echo  -e "$package\t$curCommandAtTime"  )"
    
    echo "$newLineText" >> installed.txt 
}
function addPackage_userchoose() {
    local package="$1"
    
    local newLineText="$(echo  -e "$package\t$curCommandAtTime"  )"
    
    echo "$newLineText" >> installed_user-choose.txt 
}
function addPackage_autoselect() {
    local package="$1"
    
    local newLineText="$(echo  -e "$package\t$curCommandAtTime"  )"
    
    echo "$newLineText" >> installed_auto-select.txt 
}
function addPackage_unsure() {
    local package="$1"
    
    local newLineText="$(echo  -e "$package\t$curCommandAtTime"  )"
    
    echo "$newLineText" >> installed_unsure.txt 
}

curCommandAtLine=
curCommandAtTime=
curProgram=
curZypAction=

function parseHistFileLine() 
{
    local line="$@"
    
    local time
    local line_type
    
    local full_shellcmd
    local program
    local zypper_action
    
    local package
    local sixth_col  # actually 5th after preprocess
    
    local parseZypperCmd_result
    local install_type  # user-choose | auto-select | unsure

    time="$(  echo "$line" | cut -d'|' -f 1  | sed 's/ /_/g'  )"
#     echo $time
    line_type="$(  echo "$line" | cut -d'|' -f 2 | awk '{print $1}' )"
    
    if [[ $line_type == "command" ]]; then
        curCommandAtLine=$iLine
        curCommandAtTime="$time"
        
        full_shellcmd="$(  echo "$line" | cut -d'|' -f 4  )"
        if  ( echo "$full_shellcmd" | awk '{print $1}' | grep -E "\bzypper\b" >/dev/null 2>&1 ); then # zypper
            program="zypper"
            
            parseZypperCmd_result="$(parseZypperCmd $full_shellcmd)"   # don't use quoter
            if [[ ! $parseZypperCmd_result == "FAIL" ]]; then
                zypper_action=$parseZypperCmd_result
                curZypAction=$zypper_action
#                 echo $zypper_action
            else
                echo "Failed to parse this zypper command: $full_shellcmd"
                exit 1
            fi

        else # not zypper , is yast
            curZypAction=""
            if (  echo "$line" | grep -E "\bsw_single\b"  >/dev/null 2>&1  ) ; then  # yast sw_single
                program="yast_sw_single"
            elif (  echo "$line" | grep -E "\bOneClickInstallWorker\b"  >/dev/null 2>&1  ) ; then  # yast OneClickInstallWorker
                program="OneClickInstallWorker"
            else
                program="system_installation"
            fi
        fi
        curProgram=$program

        echo -e "$time\t$program $zypper_action" >> $TMP_DIR/timesArr.txt 

        echo "" >> $TMP_DIR/installed.txt 
        echo "" >> $TMP_DIR/installed_user-choose.txt
        echo "" >> $TMP_DIR/installed_auto-select.txt   
        echo "" >> $TMP_DIR/installed_unsure.txt 
         
         
        if [[ $curZypAction == "dist-upgrade" ]]; then
            echo -e "\n---------------------------------------------------------------------------------------"
        fi
        echo "found a history command at  L$curCommandAtLine  $curCommandAtTime  $curProgram $curZypAction"
          
    elif [[ $line_type == "install" ]]; then
        package="$(  echo "$line" | cut -d'|' -f 3  )"
        
        # 判断时间    
            
            sixth_col="$(  echo "$line" | cut -d'|' -f 5  )"

            #                     manual-chosee when install system, or OneClickInstall
            if [[ "$sixth_col" == "root@install" || "$sixth_col" =~ ^[0-9]+:ruby.ruby ]]; then
                install_type="user-choose"
    #             echo "user-choose    $sixth_col"
            else

                if [[ $curProgram == "zypper" ]]; then
                    if [[ $curZypAction == "install" ]]; then
                        if [[ "$sixth_col" =~ ^root@ ]]; then
                            install_type="user-choose"
                        else
                            install_type="auto-select"
                        fi
                    else
                        install_type="auto-select"
                    fi
                elif [[ $curProgram == "yast_sw_single" ]]; then
                    if [[ ! -n $sixth_col ]]; then
                        install_type="auto-select"
                    else
                        install_type="unsure"
                    fi
                elif [[ $curProgram == "system_installation" ||  $curProgram == "OneClickInstall" ]]; then # TODO
                    # install_type  can be already valued above, If not, this package is auto-select
                    if [[ ! -n "$install_type" ]]; then
                        install_type="auto-select"
                    fi
                fi
            fi
        
#         echo $install_type

        if [[ $install_type == "user-choose" ]]; then
            removePackage "$package"
            addPackage "$package"
            addPackage_userchoose "$package"
        fi
        
        if ( ! isPackageAlreadyAdded "$package" ); then
            addPackage "$package"
            
            if [[ $install_type == "auto-select" ]]; then
                addPackage_autoselect "$package"
            elif [[ $install_type == "unsure" ]]; then
                addPackage_unsure "$package"
            fi
        fi
        
        

        
        
    elif [[ $line_type == "remove" ]]; then
        package="$(  echo "$line" | cut -d'|' -f 3  )"
        removePackage "$package"
    fi
    
}

# === begin main ===

# preprocess
cat /dev/stdin | grep -v -E "^#" | grep -v "|patch  |" | grep -v "|patch  |" | grep -v "|rremove|" | cut -d'|' -f 1,2,3,4,6  > $TMP_DIR/history.txt

# if the history begins from system installing
if ! ( cat $TMP_DIR/history.txt | head -n 1 | grep -E "^....-..-.. ..:..:..\|command\|root@install\|.*\binstallation\b" >/dev/null 2>&1  ) ; then
    echo "The input text's first line isn't yast installing system... exiting!"
    exit 1
fi


iLine=0
while read -r line 
do
    ((iLine++))
#     echo "iline=$iLine"
    
    parseHistFileLine "$line"

done < $TMP_DIR/history.txt


#  zypper se
zypper se | grep -E "^i" | awk '{print $3}' > $TMP_DIR/zypperse.txt 

echo "" >> $TMP_DIR/installed_unsure.txt 
curCommandAtTime="UnknownTime"

while read -r line  # "$line" is what's actually currently installed in system
do
    if ( ! isPackageAlreadyAdded "$line" ); then # if the "$line" is in our .txt list or not
        addPackage "$line"
        addPackage_unsure "$line"
        echo "install $line" 
    fi
done < $TMP_DIR/zypperse.txt
echo "$curCommandAtTime" >> $TMP_DIR/timesArr.txt

function isPackageReallyInstalled() {
    local package="$1"
    local package_="$( echo "$package" | sed 's/\./\\\./g' | sed 's/+/\\+/g'  )"
    if ( cat $TMP_DIR/zypperse.txt | grep -P "^$package_$"  >/dev/null 2>&1  ); then
        return 0
    else 
        return 1
    fi
}

while read -r line # $line is what's in our .txt list
do
    if [[ ! -n "$line" ]]; then
        continue
    fi
    
    if ( ! isPackageReallyInstalled "$line" ); then
        removePackage "$line"
    fi
done < <( cat $TMP_DIR/installed.txt | awk '{print $1}' )

# html

# TMP_DIR="."  #  临时
# cat $TMP_DIR/installed.txt | awk '{print $2}' | uniq | grep -v -P "^$" > $TMP_DIR/timesArr.txt

function echoHtml() {
    local IN_BODY="$1"
    echo "
        <html>
            <head>
                <style>
                    table {
                    
                    }
                    td {
                        vertical-align: top;
                    }
                    td, th {
                        border: 1px solid #b0b0b0;
                    }
                    th {
                        color: gray;
                        font-weight: normal;
                    }
                    summary {
                        color: #6372ee;
                    }
                </style>
                <script type='text/javascript'>
                    document.addEventListener('DOMContentLoaded', async function() {
                        Array.from( document.getElementsByTagName('details') ) .forEach(  function (ele) {
                            ele.open = true;
                        });
                    });
                </script>
            </head>
            <body> <code>
    "
    echo "$IN_BODY"
    echo "
            </code> </body>
        </html>
    "
}
function echoDetails() {
    local SUMMARY="$1"
    local CONTENTS="$2" 
    echo "
        <hr> 
        <div> 
        <details>
            <summary><b>$SUMMARY</b></summary>
            $CONTENTS
        </details> 
        </div>
    "
}
function echoTable() {
    local USERC="$1"
    local AUTOS="$2"
    local UNSURE="$3"
    echo "
        <div>
        <table>
            <tr>
                <th>User Choose</th>
                <th>Auto Select</th>
                <th>Unsure</th>
            </tr>
            <tr>
                <td>$USERC</td>
                <td>$AUTOS</td>
                <td>$UNSURE</td>
            </tr>
        </table>
        </div>
    
    "
}
function genTableAccrTime() {
    local time="$1"
    
    local userc
    local autos
    local unsure
    
    userc="$(  grep -P "\t$time$" $TMP_DIR/installed_user-choose.txt | awk '{print $1}' | sed 's/$/\n<br>/g' 2>/dev/null  )" 
    autos="$(  grep -P "\t$time$" $TMP_DIR/installed_auto-select.txt | awk '{print $1}' | sed 's/$/\n<br>/g' 2>/dev/null  )" 
    unsure="$(  grep -P "\t$time$" $TMP_DIR/installed_unsure.txt | awk '{print $1}' | sed 's/$/\n<br>/g' 2>/dev/null  )" 
    
    echoTable "$userc" "$autos" "$unsure"
}

BODY_CONTENT=""
function appendToBodyAccrTime() {
    local time="$1"
    local program="$2"
    
    local NEW_BODYCONTENT=""
    local NEW_TABLE
    
    NEW_TABLE="$(  genTableAccrTime "$time"  )"
    NEW_BODYCONTENT="$(  echoDetails "$time  $program" "$NEW_TABLE"  )"
    
    BODY_CONTENT="$(  echo "$BODY_CONTENT  $NEW_BODYCONTENT "   )" 
}
while read -r line 
do
    appendToBodyAccrTime "$( echo "$line" | awk  -F '\t' '{print $1}'  )" \
                         "$( echo "$line" | awk  -F '\t' '{print $2}'  )"
done < $TMP_DIR/timesArr.txt

echoHtml "$BODY_CONTENT"    > $RESULT_DIR/index.html 




# end
echo ""
wc -l $TMP_DIR/installed* | head -n 4

echo ""
echo "Open to see the report:  file://$RESULT_DIR/index.html"

