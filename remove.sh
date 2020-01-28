#!/bin/sh

# Oracle services autostart remove for Solaris 8,9,10,>10, Linux
# Yuri Voinov (C) 2006-2020
#
# ident "@(#)remove.sh   2.5   28/01/20 YV"
#

#############
# Variables #
#############

RMV_CONFIG_FILE="remove.conf"
SERVICE_NAME="oracle"
SCRIPT_NAME="init.$SERVICE_NAME"
BOOT_DIR="/etc/init.d"
CONFIG_DIR="/etc"
CONFIG_FILE_NAME="$SERVICE_NAME.conf"
CONFIG_FILE="$CONFIG_DIR/$CONFIG_FILE_NAME"
SMF_DIR="/var/svc/manifest/application/$SERVICE_NAME"
SVC_MTD="/lib/svc/method"
TMP="/tmp"

# OS Commands location variables 
CAT=`which cat`
CUT=`which cut`
ECHO=`which echo`
EGREP=`which egrep`
ID=`which id`
MV=`which mv`
RM=`which rm`
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

get_config_parameters ()
{
 # Check if remove config exists
 if [ ! -f "$RMV_CONFIG_FILE" ]; then
  $ECHO "Config file $RMV_CONFIG_FILE not found. Exiting..."
  exit 1
 else
  # Load remove config file into environment
  . $RMV_CONFIG_FILE
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

non_global_zones_r ()
{
 # Non-global zones notification
 if [ "$ZONE" != "global" ]; then
  $ECHO  "================================================================="
  $ECHO  "This is NON GLOBAL zone $ZONE. To complete uninstallation please remove"
  $ECHO  "script $SCRIPT_NAME" 
  $ECHO  "from $SVC_MTD"
  $ECHO  "in GLOBAL zone manually AFTER uninstalling autostart."
  $ECHO  "================================================================="
 fi
}

oratab_autostart_disable ()
{
 # Disabling autostart in oratab file
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

 # Disable all specified ORACLE_SID in oratab, 
 # leave disabled all others '*'-marked SIDs

 YN=`$CAT $ORATAB | $EGREP -v "#"| $EGREP -v -e "^$" | $CUT -f3 -d":"`
 if [ "$YN" = "Y" ]; then
  $SED -e 's/^[a-zA-Z0-9_+-]*:.*:/&N/' -e 's/^\*:.*:/&N/' -e 's/NY/N/' -e 's/NN/N/' $ORATAB>$TMP/ora_autostart_tmp && $MV $TMP/ora_autostart_tmp $ORATAB
 fi

 # Handling return code
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** Autostart flag in $ORATAB disablesd.";;
  *) $ECHO "*** Disabling autostart in $ORATAB has errors.";;
 esac
}

##############
# Main block #
##############

$ECHO "#####################################################"
$ECHO "#          Oracle autostart remove script           #"
$ECHO "#                                                   #"
$ECHO "# Make sure that services is stopped and disabled ! #"
$ECHO "# Press <Enter> to continue, <Ctrl+C> to cancel ... #"
$ECHO "#####################################################"
read p

# Check user root
check_root

# Get removal config
get_config_parameters

if [ "$OS_NAME" = "SunOS" ]; then
 if [ "`check_sol89`" = "1" ]; then
  # Uninstall for SunOS 8,9
  $ECHO "OS: $OS_FULL"
  $RM $BOOT_DIR/$SCRIPT_NAME>/dev/null 2>&1
  $RM -f $CONFIG_FILE>/dev/null 2>&1
  $UNLINK /etc/rc3.d/K01$SERVICE_NAME>/dev/null 2>&1
  $UNLINK /etc/rc3.d/S99$SERVICE_NAME>/dev/null 2>&1
  retcode=`$ECHO $?`
  case "$retcode" in
   0) $ECHO "*** Service deleted successfuly";;
   *) $ECHO "*** Service delete operation has errors";;
  esac
  # Disabling autostart in oratab
  oratab_autostart_disable
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete. Restart host."
 elif [ "`check_sol10_above`" = "1" ]; then
  # Uninstall for SunOS 10 or above
  $ECHO "OS: $OS_FULL"
  SVCCFG=`which svccfg`
  $SVCCFG delete -f /application/$SERVICE_NAME:default>/dev/null 2>&1
  retcode=`$ECHO $?`
  case "$retcode" in
   0) $ECHO "*** Service deleted successfuly";;
   *) $ECHO "*** Service delete operation has errors";;
  esac
  $RM $SVC_MTD/$SCRIPT_NAME>/dev/null 2>&1
  $RM -R $SMF_DIR>/dev/null 2>&1
  $RM -f $CONFIG_FILE>/dev/null 2>&1
  # Disabling autostart in oratab
  oratab_autostart_disable
  $ECHO "-------------------- Done. ------------------------"
  $ECHO "Complete."
  # Check for non-global zones uninstallation
  non_global_zones_r
 fi
elif [ "$OS_NAME" = "Linux" -a "`check_supported_linux`" = "1" ]; then
 # Uninstall for OS Linux
 $ECHO "OS: $OS_FULL"
 # Service unregistering and remove links
 CHKCONFIG=`which chkconfig`
 $CHKCONFIG --del $SCRIPT_NAME>/dev/null 2>&1
 $CHKCONFIG --level 345 $SCRIPT_NAME off>/dev/null 2>&1
 $RM $BOOT_DIR/$SCRIPT_NAME>/dev/null 2>&1
 $RM -f $CONFIG_FILE>/dev/null 2>&1
 retcode=`$ECHO $?`
 case "$retcode" in
  0) $ECHO "*** Service deleted successfuly";;
  *) $ECHO "*** Service delete operation has errors";;
 esac
 # Disabling autostart in oratab
 oratab_autostart_disable
 $ECHO "-------------------- Done. ------------------------"
 $ECHO "Complete. Restart host."
else
 $ECHO "Unsupported OS: $OS_FULL"
 $ECHO "Exiting..."
 exit 1
fi

exit 0
##