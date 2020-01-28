#!/bin/sh

# Oracle services autostart setup for Solaris 8,9,10,>10, Linux
# Yuri Voinov (C) 2006-2020
#
# ident "@(#)install.sh   2.4   28/01/20 YV"
#

#############
# Variables #
#############

INST_CONFIG_FILE="install.conf"
SERVICE_NAME="oracle"
SCRIPT_NAME="init.$SERVICE_NAME"
SMF_XML="$SERVICE_NAME.xml"
BOOT_DIR="/etc/init.d"
CONFIG_DIR="/etc"
CONFIG_FILE_NAME="$SERVICE_NAME.conf"
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"
SMF_DIR="/var/svc/manifest/application/$SERVICE_NAME"
SVC_MTD="/lib/svc/method"
TMP="/tmp"

# OS Commands location variables    
CAT=`which cat`
CHOWN=`which chown`
CHMOD=`which chmod`
CP=`which cp`
CUT=`which cut`
ECHO=`which echo`
EGREP=`which egrep`
ID=`which id`
LN=`which ln`
LS=`which ls`
MKDIR=`which mkdir`
MV=`which mv`
SED=`which sed`
UNAME=`which uname`
UNLINK=`which unlink`
WHOAMI=`which whoami`

OS_VER=`$UNAME -r|$CUT -f2 -d"."`
OS_NAME=`$UNAME -s|$CUT -f1 -d" "`
OS_FULL=`$UNAME -sr`

if [ "$OS_NAME" = "SunOS" ]; then
 ZONENAME=`which zonename`
fi

ZONE=`$ZONENAME`

###############
# Subroutines #
###############

check_install_files ()
{
 # Check needful installation files exists
 if [ ! -f $SMF_XML -a ! -f $SCRIPT_NAME -a ! -f $CONFIG_FILE_NAME -a ! -f $INST_CONFIG_FILE ]; then
  $ECHO "One or more installation files not found."
  $ECHO "Exiting..."
  exit 1
 fi
}

get_config_parameters ()
{
 # Check if install config exists
 if [ ! -f "$INST_CONFIG_FILE" ]; then
  $ECHO "Config file $INST_CONFIG_FILE not found. Exiting..."
  exit 1
 else
  # Load install config file into environment
  . $INST_CONFIG_FILE
 fi
}

check_sol89 ()
{
 # Check SunOS 5.8 or 5.9
 if [ "$OS_FULL" = "SunOS 5.9" -o "$OS_FULL" = "SunOS 5.8" ]; then
  $ECHO "1"
 else
  $ECHO "0"
 fi
}

check_sol10_above ()
{
 # Check SunOS 5.10 and above
 if [ "$OS_NAME" = "SunOS" -a "$OS_VER" -ge "10" ]; then
  $ECHO "1"
 else
  $ECHO "0"
 fi
}

check_supported_linux ()
{
 if [ "$OS_NAME" = "Linux" ]; then
  # Supported Linux: RHEL3, RHEL4, SuSE, Fedora, Oracle Enterprise Linux
  if [ -f /etc/redhat-release -o -f /etc/SuSE-release -o -f /etc/fedora-release -o -f /etc/enterprise-release ]; then
   $ECHO "1"
  else
   $ECHO "0"
  fi
 else
  $ECHO "0"
 fi
}

check_root ()
{
 # Check if user root
 if [ -f /usr/xpg4/bin/id ]; then
  WHO=`/usr/xpg4/bin/id -n -u`
 elif [ "`$ID | $CUT -f1 -d" "`" = "uid=0(root)" ]; then
  WHO="root"
 else
  WHO=$WHOAMI
 fi

 if [ ! "$WHO" = "root" ]; then
   $ECHO "ERROR: you must be super-user to run this script."
   exit 1
 fi
}

copy_init ()
{
 # Copy control script and config file
 SC_NAME=$1
 NON_10_OS=$2

 # Copy control script
 if [ "$NON_10_OS" = "1" ]; then
  if [ ! -f $BOOT_DIR/$SC_NAME ]; then
   $CP $SC_NAME $BOOT_DIR/$SC_NAME>/dev/null 2>&1
   $CHOWN -R root:sys $BOOT_DIR/$SC_NAME
  fi
 else
  if [ ! -f $SVC_MTD/$SC_NAME ]; then
   $CP $SC_NAME $SVC_MTD>/dev/null 2>&1
   $CHOWN -R root:sys $SVC_MTD/$SC_NAME
  fi
 fi

 # Copy config file
 $CP $CONFIG_FILE_NAME $CONFIG_DIR
 $CHOWN $ORACLE_OWNER:$ORACLE_GROUP $CONFIG_FILE
}

link_rc ()
{
 # Link legacy RC scripts
 SC_NAME=$1

 $UNLINK /etc/rc3.d/K01$SERVICE_NAME>/dev/null 2>&1
 $UNLINK /etc/rc3.d/S99$SERVICE_NAME>/dev/null 2>&1
 $LN -s $BOOT_DIR/$SC_NAME /etc/rc3.d/K01$SERVICE_NAME
 $LN -s $BOOT_DIR/$SC_NAME /etc/rc3.d/S99$SERVICE_NAME
}

check_group_dba ()
{
 # Check oracle main group exists
 par_group=$1
 GR_NAME=`$CAT /etc/group|$EGREP $par_group|$CUT -f1 -d":"`

 if [ "$GR_NAME" != "$par_group" ]; then
  $ECHO "ERROR: Group $par_group does not exists. Make sure Oracle software installed."
  $ECHO "Exiting..."
  exit 1
 fi
}

make_smf ()
{
 # Make SMF entry
 SVCCFG=`which svccfg`

 if [ ! -d $SMF_DIR ]; then
  $MKDIR $SMF_DIR
 fi
 $CP $SMF_XML $SMF_DIR
 $CHOWN -R root:sys $SMF_DIR
 $SVCCFG validate $SMF_DIR/$SMF_XML>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** XML service descriptor validation successful";;
  *) $ECHO "*** XML service descriptor validation has errors";;
 esac
 $SVCCFG import $SMF_DIR/$SMF_XML>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** XML service descriptor import successful";;
  *) $ECHO "*** XML service descriptor import has errors";;
 esac
}

link_smf ()
{
 # Link script to SMF method
 SC_NAME=$1

 $UNLINK $SVC_MTD/$SC_NAME>/dev/null 2>&1
 $LN -s $BOOT_DIR/$SC_NAME $SVC_MTD/$SC_NAME
}

verify_svc ()
{
 # Installed service verification
 SC_NAME=$1

 $ECHO "------------ Service verificstion ----------------"
 if [ "$OS_NAME" = "SunOS" ]; then
  if [ "`check_sol89`"  = "1" ]; then
   $LS -al /etc/rc3.d/*$SERVICE_NAME
  elif [ "`check_sol10_above`" = "1" ]; then
   SVCS=`which svcs`
   $LS -al $SVC_MTD/$SC_NAME
   $LS -l $SMF_DIR
   $SVCS $SERVICE_NAME
  fi
 else
  $LS -al /etc/rc3.d/*$SERVICE_NAME
  $LS -al /etc/rc0.d/*$SERVICE_NAME
 fi
  $LS -al $CONFIG_FILE
}

non_global_zones ()
{
 # Non-global zones notification
 if [ "$ZONE" != "global" ]; then
  $ECHO "=============================================================="
  $ECHO "This is NON GLOBAL zone $ZONE. To complete installation please copy"
  $ECHO "script $SCRIPT_NAME" 
  $ECHO "to $SVC_MTD"
  $ECHO "in GLOBAL zone manually BEFORE starting service by SMF."
  $ECHO "Note: Permissions on $SCRIPT_NAME must be set to root:sys."
  $ECHO "============================================================="
 fi
}

oratab_autostart_enable ()
{
 # Enabling autostart in oratab file
 # Try to find an oratab file
 if [ -z "$ORATAB" ]; then
  if [ -f /var/opt/oracle/oratab ]; then
   ORATAB="/var/opt/oracle/oratab"  # Solaris-type location
  elif [ -f /etc/oratab ]; then
   ORATAB="/etc/oratab"             # Linux/HPUX-type location
  else
   $ECHO "ERROR: Could not find oratab file."
  fi
 elif [ ! -f $ORATAB ]; then
  $ECHO "ERROR: Could not find oratab: '$ORATAB' "
 fi

 # Enable all specified ORACLE_SID in oratab,
 # leave disabled all others '*'-marked SIDs

 YN="`$CAT $ORATAB | $EGREP -v '#'| $EGREP -v -e '^$' | $CUT -f3 -d':'`"
 if [ "$YN" = "N" ]; then
  $SED -e 's/^[a-zA-Z0-9_+-]*:.*:/&Y/' -e 's/^\*:.*:/&N/' -e 's/YN/Y/' -e 's/NN/N/' $ORATAB>$TMP/ora_autostart_tmp && $MV $TMP/ora_autostart_tmp $ORATAB
 fi

 # Handling return code
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** Autostart flag in $ORATAB enabled.";;
  *) $ECHO "*** Enabling autostart in $ORATAB has errors.";;
 esac
}

##############
# Main block #
##############

$ECHO "#####################################################"
$ECHO "#       Oracle autostart installation script        #"
$ECHO "#                                                   #"
$ECHO "# Press <Enter> to continue, <Ctrl+C> to cancel ... #"
$ECHO "#####################################################"
read p

# Check user root
check_root

# Check installation files
check_install_files

# Get installation config
get_config_parameters

if [ "$OS_NAME" = "SunOS" ]; then
 if [ "`check_sol89`" = "1" ]; then
  # Install for SunOS 5.8,5.9
  $ECHO "OS: $OS_FULL"
  copy_init $SCRIPT_NAME 1
  check_group_dba $ORACLE_GROUP
  $CHOWN root:dba $BOOT_DIR/$SCRIPT_NAME
  $CHMOD 755 $BOOT_DIR/$SCRIPT_NAME
  link_rc $SCRIPT_NAME
  # Verify installation
  verify_svc $SCRIPT_NAME
  # Enabling autostart in oratab
  oratab_autostart_enable
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete. Check $SCRIPT_NAME working and if true,"
  $ECHO "restart host to verify."
 elif [ "`check_sol10_above`" = "1" ]; then
  # Install for SunOS 5.10 or above
  $ECHO "OS: $OS_FULL"
  copy_init $SCRIPT_NAME 0
  $CHOWN root:sys $SVC_MTD/$SCRIPT_NAME
  $CHMOD 755 $SVC_MTD/$SCRIPT_NAME
  make_smf
  # Verify installation
  verify_svc $SCRIPT_NAME
  # Enabling autostart in oratab
  oratab_autostart_enable
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete. Check $SCRIPT_NAME working and if true,"
  $ECHO "enable service by svcadm."
  # Check for non-global zones installation
  non_global_zones
 fi
elif [ "$OS_NAME" = "Linux" -a "`check_supported_linux`" = "1" ]; then
 # Install for Linux
 $ECHO "OS: $OS_FULL"
 CHKCONFIG=`which chkconfig`
 copy_init $SCRIPT_NAME 1
 check_group_dba $ORACLE_GROUP
 $CHOWN root:dba $BOOT_DIR/$SCRIPT_NAME
 $CHMOD 755 $BOOT_DIR/$SCRIPT_NAME
 # Service registration and add links
 $CHKCONFIG --add $SCRIPT_NAME>/dev/null 2>&1
 $CHKCONFIG --level 345 $SCRIPT_NAME on>/dev/null 2>&1
 # Verify installation
 verify_svc $SCRIPT_NAME
 # Enabling autostart in oratab
 oratab_autostart_enable
 $ECHO "-------------------- Done. ------------------------"
 $ECHO "Complete. Check $SCRIPT_NAME working and if true,"
 $ECHO "restart host to verify."
else
 $ECHO "Unsupported OS: $OS_FULL"
 $ECHO "Exiting..."
 exit 1
fi

exit 0
##