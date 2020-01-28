                      ***************
                      * Version 2.5 *
                      ***************

Note:  This  version  supports custom  LD_PRELOAD_64  memory
allocator  for  Oracle  RDBMS  and  listener.  Specify it in
ADD_VAL in oracle.conf to use. We're assumes Oracle RDBMS is
64  bit  only.  To use with 32 bit Oracle, require to modify
init.oracle script.

This  package  is  written  for  Oracle  services  autostart
activation and deactivation in one step on next systems:

- Solaris 8,9
- Solaris 10 and above
- Linux (RHEL3 and above, SuSE, Fedora, 
         Oracle Enterprise Linux/Oracle Unbreakable Linux)

Supported autostart for this services:
- Oracle RDBMS
- Oracle ASM
- Oracle TNS Listener
- Oracle DB Console (OEM)
- Oracle iSQL*Plus
- Oracle HTTP Server (OHS/Apache)

OHS  autostart  supported from Database Companion CD and iAS
Companion CD.

Also  supported  autostart  several  RDBMS/ASM services from
single oratab file.

Note:   Autostart    ASM+RDBMS    combinations  executes  in
correct sequence.

For  Oracle  autostart  execution  uses  init.oracle script.
Depending on platform (Solaris 8-10 and above), installation
script  creates links in /etc/rc3.d, or register service and
links  create  with  chkconfig  command, or register service
in SMF.

Platform recognition is automatic.

Install/remove script configuration
-----------------------------------

For  autostart  service installation uses install.sh script,
for remove autostart (not Oracle services!) remove.sh.

This  scripts  using  own configuration files, which permits
to    change   oratab   location   (by   default   is   /etc
or   /var/opt/oracle)  and  Oracle  software  owner  (oracle
by default) and main Oracle group (dba by default).

This   parameters   will   used   only  if  you  environment
is different from historically defaults.

When    using   standard   environment  settings,  let  this
settings intact.

Service configuration
---------------------

Autostart  configuration parameters is in oracle.conf config
file   (default  template,  will  be  copy  in  /etc  during
installation).

You can edit next settings:

```
#
# Additional LD_PRELOAD_64 value. Leave blank if no
#
ADD_VAL=""
#ADD_VAL="/usr/local/lib/ltalloc/64/libltalloc.so"
^^^^^^^^^ Specify custom allocator here. Specify either full
path to library, or (in case of libmtmalloc.so) just library
name.  Make  sure your security settings permit loading from
specified directory. Disabled by default.

#
# oratab location. 
# Leave variable blank to use /var/opt/oracle/oratab
#
ORATAB=""
^^^^^^^^^ On some platforms you must specify oratab location
explicity,    if    oratab    not    in    standard   places
(/var/opt/oracle/oratab   or  /etc/oratab).  Specifies  full
absolute  path and oratab file name (not exactly oratab, but
with expected oratab structure).

IMPORTANT - autostart flag in oratab file will set explicity
when  autostart  installs  (to  Y)  and  revert  to  N  when
autostart deinstalls.

#
# ORACLE_SID and ORACLE_HOME variables. 
# Leave variables blank to use oratab
#
ORACLE_SID=""
ORACLE_HOME=""
^^^^^^^^^^^^^  If  parameters specified explicity, they will
be  used  for RDBMS/Listener startup/shutdown against oratab
contents.

#
#  Startup/shutdown  privilege  for  "connect  as"  to RDBMS
#  instance(s).
# By default is "sysdba".
#
#ORACLE_DB_PRIV="sysoper"
ORACLE_DB_PRIV="sysdba"
^^^^^^^^^^^^^^^^^^^^^^   Oracle   privilege,  which  permits
startup/shutdown.  By  default  is  sysdba. Can be different
in your system (specifies during oracle installation).

#
#   Startup/shutdown  privilege  for  "connect  as"  to  ASM
#   instance(s).
# By default is "sysdba" (Oracle 10),
# set to "sysasm" for Oracle 11 and above.
#
#ORACLE_ASM_PRIV="sysasm"
ORACLE_ASM_PRIV="sysdba"
^^^^^^^^^^^^^^^^^^^^^^^^      Oracle      privilege      for
startup/shutdown  ASM  instances.  In  Oracle  10  -  sysdba
by default, in Oracle 11 and above - sysasm.

#
# ASM shutdown mode. In some cases (not patched DB etc.) ASM
# instance cannot shutdown in immediate mode after correctly
# shutdown main DB  and  must be stopped # in shutdown abort
# mode.
#
# Beware, that this stop mode can damage your ASM diskgroups!
#
#ASM_SHUTDOWN_MODE="abort"
ASM_SHUTDOWN_MODE="immediate"
^^^^^^^^^^^^^^^^^^^^^^^^^^^^^  ASM  instances shutdown mode.
In  some  rare  cases  after shutdown database instances ASM
cannot  stop  in immediate mode (database not patched etc.).
For addressing this issue you can specify stop ASM instances
in  abort  mode. Note, this mode can damage ASM mounted disk
groups and not recommended.

#
# Standalone Apache home (OHS Home). Set if OHS installed
# and must be started/stopped, leave blank of not.
# Note: Supported both OHS - from Database Companion CD and
#       from iAS Companion CD.
#
#OHSHOME="/export/home/OraHome2/app/oracle/product/10.2.0"
OHSHOME=""
^^^^^^^   OHS   home   directory.   Uses  in  explicit  mode
to startup/shutdown OHS. Leave it blank if not use OHS.

#
# If OHS use ports <1024 (i.e 80 and/or 443), 
# set OHSPORT to 80. 
# Otherwise leave it blank
#
OHSPORT=""
^^^^^^^^^^^^^^^^^  This  parameter  NOT  SPECIFY OHS binding
port.  It  only  use  in  control  script  for  OHS  control
purposes.  Binding  OHS  to  80  port  must  be  done  using
httpd.conf.   This  parameter  specifies,  if  startup  will
be  done  from root in cases binding OHS on privileged ports
(<1024),   or  from  oracle  software  owner  (for  example,
if binds on port 7777 or 7778). Note, that root can bind OHS
on  any  port,  against,  binding  on  privileged  port must
be done only from root or RBAC equivalent.

#
#   If  SSL  configured,  this  variable  must  be set to 1.
# Otherwise leave it blank
#
#OSSL="1"
OSSL=""
^^^^^^^^^^^^^^^^^^^^^^^  Parameter  using to tell OHS to use
SSL  mode when OHS controls with apachectl. If OPMN uses for
control  OHS (next parametter) for enabling SSL will be used
ssl_enabled OPMN parameter and this setting will be ignore.

#
# If using OPMN for start OHS, set USEOPMN to 1.
# For use apachectl, leave it blank.
#
USEOPMN=""
^^^^^^^^^^ This specify to use OPMN to control OHS, if blank
and  OHSHOME  specified,  apachectl will be used. If OHS not
installed  or  must  not  be  started  automatically,  leave
parameter OHSHOME blank (above).

#
# If configured OEM dbconsole, set USEOEM to 1. 
# Leave blank if not.
#
USEOEM=""
^^^^^^^^^^  If dbconsole is configured (Oracle 10 and above)
and  need  to start it during autostart, set this parameter.
To  use dbconsole in WAN environments, secure dbconsole with
SSL  first  (i.e.,  emctl secure dbconsole command). In some
very rare cases dbsonsole cannot be start automatically from
autostart and must be start manually.

#
# If configured iSQL*Plus, set USEISQLPLUS to 1. 
# Leave blank if not.
#
USEISQLPLUS=""
^^^^^^^^  Specify  this  if you need to autostart iSQL*Plus.
Do  NOT  use  iSQL*Plus  on  high  security  systems or with
Internet access.

#
# Log file. Default /var/log/oracle.log
#
LOG="/var/log/oracle.log"
^^^^^^^^^^^^^^^^^ Full path and logfile name. If logfile not
exists, it will be created during init.oracle execution.
```

Autostart installation
----------------------

To  install  autostart  you  need  to  unpack archive in any
directory  and  run  install.sh  from  root.  After that all
needful  files  will  be  installed  in  system  and you can
activate  autostart  with  reboot  host (Solaris 8,9, Linux)
or with SMF command (Solaris 10 and above):

```
# svcadm enable oracle
```

You  can  check  services start process in separate terminal
session:

```
# tail -f /var/log/oracle.log       (Logfile and path can be
different   and  specifies  in  oracle.conf  file  with  LOG
parameter)
```

Control   script   can  be  called  interactively  (i.e. for
debugging purposes):

```
root @ server /lib/svc/method # init.oracle start
init.oracle will execute start for services:
Listener:started.
+ASM:started.
SUN11:started.
```

For  this  operations  disable  service  with  SMF interface
first, otherwise SMF will restart services itself.

Autostart uninstall
-------------------

For stop and uninstall autostart service do:

- For Solaris 8,9, Linux:
1. Stop Oracle services manually;
2. Run remove.sh as root

- For Solaris 10 and above:
1. Run command:
```
   # svcadm disable oracle
```
2. Run remove.sh as root.

On  Solaris  10  and above use only SMF interface to control
oracle  services  (with  svcs/svcadm commands).

Notes:
======

1.  If  you  want  to  run  OHS from root account (i.e. when
binding  to  the  <1024  ports) as by OPMN as apachectl, you
need to change owner for apachectl:

```
# chown root:dba apachectl
```

2. Install/remove scripts use some rules, i.e:
-  They  must  be run in multi-user (run level 3). Otherwise
in  some  cases most system utilities will be not accessable
and scripts cannot be run correctly.
-  Required  run  level for init.oracle execution is 3 (i.e.
autostart will not work in single-user mode).
-  Installation/remove  scripts  must be run as root. If not
root, execution will be terminated with return code 1.
-   Oracle   services  must  be  stopped   manually   before
autostart  installation/remove.  If  Oracle services running
during  autostart  installation,  they  will  running  after
installation  too,  but  when  you enable SMF FMRI, services
will be stopped first and then starts again.

3.  In  some  rare  cases on Solaris x86 with OPMN can occur
long delay to start web-services or unavailability OPMN main
process  startup. To workaround you must run opmnctl stopall
then  opmnctl  startall. If OHS could not start again, check
OPMN/OHS logs to correct misconfiguration.

4.  If  installing  Oracle  services into Solaris Containers
(Zones),  you  need  to copy main control script init.oracle
to  /lib/svc/method  directory  in global zone with root:sys
permissions manually BEFORE enabling autostart.

Note,  that  in  non-global zones this directory mounts from
global  zone with loopback and read-only permissions and you
cannot  correctly install control method into this directory
from non-global zone.
