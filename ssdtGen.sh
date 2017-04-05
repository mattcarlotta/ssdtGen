#!/bin/bash
#
# Script (ssdtGen.sh) to create SSDTs for Mac OS.
#
# Version 0.0.7beta - Copyright (c) 2017 by M.F.C.
#
# Introduction:
#     - ssdtGen is an automated bash script that attempts to build and
#        compile SSDTs for X99 systems running Mac OS!
#     - Simply run the commands in the README to download and execute the
#        ssdtGen.sh file from your Desktop.
#
#
# Bugs:
#     - Bug reports can be filed at: https://github.com/mattcarlotta/ssdtGen/issues
#        Please provide clear steps to reproduce the bug and the output of the
#        script. Thank you!
#

#===============================================================================##
## GLOBAL VARIABLES #
##==============================================================================##

# Debug output path
dPath="$HOME/Desktop/debug_output.txt"

# User's home dir
gPath="$HOME/Desktop"

#DSDT external device path
gExtDSDTPath='_SB_.PCI0'

#SSDT's standard device path
gSSDTPath='_SB.PCI0'

#SSDT being built/compile set by printHeader
gSSDT=""

#SSDT's Table ID set by printHeader
gSSDTID=""

#Currently logged in user
gUSER=$(stat -f%Su /dev/console)

#IASL root compiler directory
gIaslRootDir="/usr/bin/iasl"

#IASL local  directory
gUsrLocalDir="/usr/local/bin"

#IASL local compiler directory
gIaslLocalDir="/usr/local/bin/iasl"

# Github IASL download
gIaslGithub="https://raw.githubusercontent.com/mattcarlotta/ssdtGen/master/tools/iasl"

#Count to cycle thru arrays
gCount=0

# Bold text
bold=$(tput bold)

# Normal text
normal=$(tput sgr0)

#SSDT Table-ID array
gTableID=(
[0]='ALZA'
[1]='EVMR'
[2]='EVSS'
[3]='GFX1'
[4]='GLAN'
[5]='HECI'
[6]='LPC0'
[7]='SAT1'
[8]='SMBS'
[9]='XHC'
[10]='XOSI'
)

#SSDT Table Length array
gTableLength=(
[0]="0x000000ED (237)"
[1]="0x00000108 (264)"
[2]="0x0000013A (314)"
[3]="0x0000037C (892)"
[4]="0x000000E6 (230)"
[5]="0x000000FE (254)"
[6]="0x00000078 (120)"
[7]="0x00000138 (312)"
[8]="0x000000B6 (182)"
[9]="0x0000016F (367)"
[10]="0x000000B0 (176)"
)

#SSDT Table Checksum array
gTableChecksum=(
[0]='0xBC'
[1]='0x5F'
[2]='0x02'
[3]='0x89'
[4]='0x53'
[5]='0x78'
[6]='0x11'
[7]='0x9E'
[8]='0x7F'
[9]='0xF4'
[10]='0xA2'
)


# 0 ALZA, Length  0x000000ED (237), Checksum 0xBC, Device
# 1 EVMR, Length  0x00000108 (264), Checksum 0x5F, Device
# 2 EVSS, Length  0x0000013A (314), Checksum 0x02, _DSM
# 3 GFX1, Length  0x0000037C (892), Checksum 0x89, Device
# 4 GLAN, Length  0x000000E6 (230), Checksum 0x53, _DSM
# 5 HECI, Length  0x000000FE (254), Checksum 0x78, Device
# 6 LCP0, Length  0x00000078 (120), Checksum 0x11, _DSM
# 7 SAT1, Length  0x00000138 (312), Checksum 0x9E, _DSM
# 8 SMBS, Length  0x000000B6 (182), Checksum 0x7F, Device
# 9 XHC,  Length  0x0000016F (367), Checksum 0xF4, _DSM
# 10 XOSI,Length  0x000000B0 (176), Checksum 0xA2, Special

#===============================================================================##
## USER ABORTS SCRIPT #
##==============================================================================##
function _clean_up()
{
  printf "Cleaning up any left-overs..."
  rm "${gPath}"/*.dsl 2> /dev/null
  sleep 1
  printf "Script was aborted!\033[0K\r\n"
  exit 1
  clear
}

#===============================================================================##
## DISPLAY INSTRUCTIONS #
##==============================================================================##
function display_instructions()
{
  printf "\n"
  printf "To build and compile all SSDTS, input ${bold}-ba${normal} or ${bold}-BA${normal}\n"
  printf "\n"
  printf "To build and compile one SSDT, input ${bold}-b NAME${normal} or ${bold}-BA NAME${normal}:\n"
  printf "\n"
  printf "       - ${bold}ALZA${normal}: Adds support for Realtek on-board sound\n"
  printf "       - ${bold}EVMR${normal}: Server Platform Service Rom functionality and support\n"
  printf "          for MS SMBus transactions\n"
  printf "       - ${bold}EVSS${normal}: Adds support for a third PCH sSata controller for IDE, AHCI,\n"
  printf "          RAID storage drives (up to 6Gb/s transfers) \n"
  printf "       - ${bold}GFX1${normal}: Adds suport for a single Nvidia graphics card and\n"
  printf "          adds HDMI audio support for the card as well \n"
  printf "       - ${bold}GLAN${normal}: Adds support for an Intel ethernet controller\n"
  printf "       - ${bold}HECI${normal}: Intel Management Engine Interface that, in general,\n"
  printf "          adds support for various tasks while the system is booting, running \n"
  printf "          or sleeping \n"
  printf "       - ${bold}LPC0${normal}: Adds support to AppleLPC.kext for Low Pin Count devices\n"
    printf "          to connect to the CPU\n"
  printf "       - ${bold}SAT1${normal}: Adds support for the PCH SATA controller for SATA devices\n"
  printf "          via Legacy or AHCI mode (up to 6Gb/s transfers)\n"
  printf "       - ${bold}SMBS${normal}: Adds support for a SMBus controller that allows communication\n"
  printf "          between separate hardware devices and adds I2C support (temperature,\n"
  printf "          fan, voltage, and battery sensors)\n"
  printf "       - ${bold}XHC${normal}: Adds power options for the USB xHC Host Controller\n"
  printf "       - ${bold}XOSI${normal}: Adds Windows simulated support for DSDT OSI_ methods\n"
  printf "\n"
  printf "To debug the script, input ${bold}-d${normal} or ${bold}-D${normal}:\n"
  printf "       - Will automatically attempt to build and compile all SSDTS while\n"
  printf "          generating a debug ouput.txt file to the Desktop\n"
  printf "\n"
  while true; do
    read -p "Would you like to reload the script now? (y/n)? " choice
    case "$choice" in
      y|Y )
        main
        break  # supported key, break;
      ;;

      n|N )
        echo ''
        _clean_up
        break  # supported key, break;
      ;;

      * )
        printf "${bold}*—-ERROR—-*${normal} That was not a valid option, please try again!\n"
      ;;
    esac
done
}


#===============================================================================##
## CHECK SIP #
##==============================================================================##
function _getSIPStat()
{
  case "$(/usr/bin/csrutil status)" in
    "System Integrity Protection status: enabled." )
      printf "${bold}*—-WARNING--*${normal} S.I.P is enabled...\n"
      printf "Its recommended (not required) that you completely disable S.I.P. by setting CsrActiveConfig to 0x67 in your config.plist!\n"
      ;;

    *"Filesystem Protections: enabled"* )
      printf "${bold}*—-WARNING--*${normal} S.I.P. is partially disabled, but file system protection is still enabled...\n"
      printf "It/s recommended (not required) that you completely disable S.I.P. by setting CsrActiveConfig to 0x67 in your config.plist!\n"
      ;;

    * )
      ;;
  esac
}

#===============================================================================##
## CHECK MACIASL AND IASL ARE INSTALLED #
##==============================================================================##
function _checkPreInstalled()
{
  if [ -f "$gIaslRootDir" ] || [ -f "$gIaslLocalDir" ];
    then
      echo 'IASL64 is already installed!' > /dev/null 2>&1
    else
      printf "${bold}*—-ERROR—-*${normal} IASL64 isn't installed in the either $gIaslRootDir nor your $gIaslLocalDir directory!\n"
      printf " \n"
      printf "Attempting to download IASL from Github...\n"
      if [ ! -d "$gUsrLocalDir" ];
        then
          echo "$gUsrLocalDir doesn't exist. Creating directory!"
          mkdir -p $gUsrLocalDir
        else
          echo "$gUsrLocalDir already exists" > /dev/null 2>&1
      fi
      curl -o $gIaslLocalDir $gIaslGithub
      if [[ $? -ne 0 ]];
        then
          printf ' \n'
          printf "${bold}*—-ERROR—-*${normal} Make sure your network connection is active!\n"
          exit 1
      fi
      chmod +x $gIaslLocalDir
      printf " \n"
      printf "MaciASL has been installed!\n"
      printf " \n"
  fi
}

#===============================================================================##
## CHECK DEVICE PROP IS NOT EMPTY #
##==============================================================================##
function _checkDevice_Prop()
{
  SSDT_VALUE=$1
  SSDT_DEVICE=$2
  SSDT_PROP=$3

  if [ -z "$SSDT_VALUE" ]
    then
      echo ''
      echo "${bold}*—-ERROR—-*${normal} There was a problem locating $SSDT_DEVICE's $SSDT_PROP!"
      echo "Please run this script in debug mode to generate a debug text file."
      echo ''
      #_clean_up
  fi
}

#===============================================================================##
## EOF BRACKETS #
##==============================================================================##
function _close_Brackets()
{
  MB=$1

  #if [[ "$addDTGP" == true]];
    #then
    #echo '            }, Local0)'                                                        >> "$gSSDT"
    #echo '           DTGP (Arg0, Arg1, Arg2, Arg3, RefOf (Local0))'                      >> "$gSSDT"
    #echo '           Return (Local0)'                                                    >> "$gSSDT"
  #else
  echo '            })'                                                                   >> "$gSSDT"
  #fi

  echo '        }'                                                                        >> "$gSSDT"
  echo '    }'                                                                            >> "$gSSDT"

  if [ "$MB" = true ];
    then
    echo '   }'                                                                           >> "$gSSDT"
    echo '  }'                                                                            >> "$gSSDT"
  fi
}

#===============================================================================##
## SET DEVICE PROPS #
##==============================================================================##
function _setDevice_NoBuffer()
{
  PROP=$1
  VALUE=$2

  echo '                '$PROP','                                                         >> "$gSSDT"
  echo '                '$VALUE','                                                        >> "$gSSDT"
}

#===============================================================================##
## SET DEVICE PROPS #
##==============================================================================##
function _setDeviceProp()
{
  PROP=$1
  VALUE=$2

  echo ''                                                                                 >> "$gSSDT"
  echo '                '$PROP','                                                         >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    '$VALUE''                                                     >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## FIND DEVICE PROP #
##==============================================================================##
function _findDeviceProp()
{
  PROP=$1
  local PROP2=$2
  echo $PROP2
  if [ ! -z "$PROP2" ];
    then
      SSDT_VALUE=$(ioreg -p IODeviceTree -n "$DEVICE" -k $PROP2 | grep $PROP2 |  sed -e 's/ *["|=:/_@]//g; s/'$PROP2'//g')
      echo $SSDT_VALUE
    else
      SSDT_VALUE=$(ioreg -p IODeviceTree -n "$DEVICE" -k $PROP | grep $PROP |  sed -e 's/ *["|=<A-Z>:/_@]//g; s/'$PROP'//g')
  fi

  _checkDevice_Prop "${SSDT_VALUE}" "$DEVICE" "$PROP"

  echo ''                                                                                 >> "$gSSDT"
  echo '                "'$PROP'",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"

  if [[ "$PROP" == 'compatible' ]];
    then
      echo '                    "'$SSDT_VALUE'"'                                          >> "$gSSDT"
    elif [[ "$PROP" == 'device-id' ]] || [[ "$PROP" == 'subsystem-vendor-id' ]];
    then
      echo '                    0x'${SSDT_VALUE:0:2}', 0x'${SSDT_VALUE:2:2}', 0x00, 0x00' >> "$gSSDT"
    else
      echo '                    0x00, 0x'${SSDT_VALUE:2:2}', 0x00, 0x00'                  >> "$gSSDT"
  fi
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## SET DEVICE STATUS #
##==============================================================================##
function _setGPUDevice_Status()
{
  D0XX=$(ioreg -p IODeviceTree -n ${PCISLOT} -r | grep D0 | sed -e 's/ *["+|=<a-z>:/_@-]//g; s/^ *//g')
  D0XX=${D0XX:0:4}

  _checkDevice_Prop "${D0XX}" "$PCISLOT" "D0XX device"

  echo ''                                                                                 >> "$gSSDT"
  echo '    Name ('${gSSDTPath}'.'${PCISLOT}'.'${GPU}'._STA, Zero)  // _STA: Status'      >> "$gSSDT"
  echo '    Name ('${gSSDTPath}'.'${PCISLOT}'.'${AUDIO}'._STA, Zero)  // _STA: Status'    >> "$gSSDT"
  echo '    Name ('${gSSDTPath}'.'${PCISLOT}'.'${D0XX}'._STA, Zero)  // _STA: Status'     >> "$gSSDT"
  echo '}'                                                                                >> "$gSSDT"
}

#===============================================================================##
## SET DEVICE STATUS #
##==============================================================================##
function _setDevice_Status()
{
  echo ''                                                                                 >> "$gSSDT"
  echo '    Name ('${gSSDTPath}'.'$SSDT'._STA, Zero)  // _STA: Status'                    >> "$gSSDT"
  echo '}'                                                                                >> "$gSSDT"
}

#===============================================================================##
## GRAB LEqual or LNot _DSM #
##==============================================================================##
function _getDSM()
{
  local DSM=$1

  if [ "$DSM" = true ];
    then
      echo '            If (LNot (Arg2))'                                                 >> "$gSSDT"
    else
      echo '        Method (_DSM, 4, NotSerialized)'                                      >> "$gSSDT"
      echo '        {'                                                                    >> "$gSSDT"
      echo '            If (LEqual (Arg2, Zero))'                                         >> "$gSSDT"
  fi

  echo '            {'                                                                    >> "$gSSDT"
  echo '                Return (Buffer (One)'                                             >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x03'                                                         >> "$gSSDT"
  echo '                })'                                                               >> "$gSSDT"
  echo '            }'                                                                    >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  #if [[ "$addDTGP" == true]];
    #then
    #echo '            Store (Package ()'                                                 >> "$gSSDT"
    #else
  echo '            Return (Package ()'                                                   >> "$gSSDT"
  #fi
  echo '            {'                                                                    >> "$gSSDT"
}

#===============================================================================##
## FIND AUDIO PROPS #
##==============================================================================##
function _findAUDIO()
{
  DEVICE="${DEVICE:0:3}1"
  AUDIO=$DEVICE

  echo ''                                                                                 >> "$gSSDT"
  echo '    Device ('${gSSDTPath}'.'${PCISLOT}'.HDAU)'                                    >> "$gSSDT"
  echo '    {'                                                                            >> "$gSSDT"
  echo '        Name (_ADR, One)  // _ADR: Address'                                       >> "$gSSDT"
  _getDSM
}


#===============================================================================##
## FIND GPU PROPS #
##==============================================================================##
 function _findGPU()
 {
  PROP='attached-gpu-control-path'
  GPUPATH=$(ioreg -l | grep $PROP | sed -e 's/ *[",|=:<a-z>/_@-]//g; s/IOSAACPIPEPCI00AACPIPCI//g; s/3IOPP//g; s/0NVDADC2NVDAAGPM//g')
  PCISLOT=${GPUPATH:0:4} #BR3A
  DEVICE=${GPUPATH:4:4} #H000
  GPU=$DEVICE

  local PROP2='device-id'
  GPUDEVID=$(ioreg -p IODeviceTree -n $DEVICE -r -k $PROP | grep $PROP2 | sed -e 's/ *[",|=<>:/_@]//g; s/'$PROP2'//g')

  _checkDevice_Prop "${GPUPATH}" "$SSDT" "$PROP"

  echo '    Device ('${gSSDTPath}'.'${PCISLOT}'.'${SSDT}')'                               >> "$gSSDT"
  echo '    {'                                                                            >> "$gSSDT"
  echo '        Name (_ADR, Zero)  // _ADR: Address'                                      >> "$gSSDT"
  _getDSM

 }

 #===============================================================================##
 ## GRAB WINDOWS OSI  #
 ##==============================================================================##
 function _getWindows_OSI()
 {
   echo '    Method (XOSI, 1)'                                                            >> "$gSSDT"
   echo '    {'                                                                           >> "$gSSDT"
   echo '        Store(Package()'                                                         >> "$gSSDT"
   echo '        {'                                                                       >> "$gSSDT"
   echo '            "Windows",                // generic Windows query'                  >> "$gSSDT"
   echo '            "Windows 2001",           // Windows XP'                             >> "$gSSDT"
   echo '            "Windows 2001 SP2",       // Windows XP SP2'                         >> "$gSSDT"
   echo '             //"Windows 2001.1",      // Windows Server 2003'                    >> "$gSSDT"
   echo '            //"Windows 2001.1 SP1",   // Windows Server 2003 SP1'                >> "$gSSDT"
   echo '            "Windows 2006",           // Windows Vista'                          >> "$gSSDT"
   echo '            "Windows 2006 SP1",       // Windows Vista SP1'                      >> "$gSSDT"
   echo '            //"Windows 2006.1",       // Windows Server 2008'                    >> "$gSSDT"
   echo '            "Windows 2009",           // Windows 7/Windows Server 2008 R2'       >> "$gSSDT"
   echo '            "Windows 2012",           // Windows 8/Windows Server 2012'          >> "$gSSDT"
   echo '            //"Windows 2013",         // Windows 8.1/Windows Server 2012 R2'     >> "$gSSDT"
   echo '            "Windows 2015",           // Windows 10/Windows Server TP'           >> "$gSSDT"
   echo '        }, Local0)'                                                              >> "$gSSDT"
   echo '       Return (Ones != Match(Local0, MEQ, Arg0, MTR, 0, 0))'                     >> "$gSSDT"
   echo '    }'                                                                           >> "$gSSDT"
   echo '}'                                                                               >> "$gSSDT"
 }

 #===============================================================================##
 ## FIND SMBS DEVICE  #
 ##==============================================================================##
 function _findDevice_Address()
 {
   DEVICE=$1
   PROP='acpi-path'
   SSDTADR=$(ioreg -p IODeviceTree -n "$DEVICE" -k $PROP | grep $PROP |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/acpipathlane//g; y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
   _checkDevice_Prop "${SSDTADR}" "$DEVICE" "$PROP"

   echo '    Device ('${gSSDTPath}'.SBUS)'                                                >> "$gSSDT"
   echo '    {'                                                                           >> "$gSSDT"
   echo '        Name (_ADR, 0x'${SSDTADR}')  // _ADR: Address'                           >> "$gSSDT"
   echo '        Device (BUS0)'                                                           >> "$gSSDT"
   echo '        {'                                                                       >> "$gSSDT"
   echo '            Name (_CID, "smbus") // _CID: Compatible ID'                         >> "$gSSDT"
   echo '            Name (_ADR, Zero)'                                                   >> "$gSSDT"
   echo '            Device (DVL0)'                                                       >> "$gSSDT"
   echo '            {'                                                                   >> "$gSSDT"
   echo '                   Name (_ADR, 0x57)'                                            >> "$gSSDT"
   echo '                   Name (_CID, "diagsvault")'                                    >> "$gSSDT"
   _getDSM
 }

#===============================================================================##
## GRAB EXTERNAL DEVICE ADDRESS #
##==============================================================================##
function _getExtDevice_Address()
{
  DEVICE=$1

  if [[ "$DEVICE" == "XHC" ]];
    then
      local underscore="_"
  fi

  echo '    External ('${gExtDSDTPath}'.'${DEVICE}''${underscore}', DeviceObj)'           >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '    Method ('${gSSDTPath}'.'${DEVICE}'._DSM, 4, NotSerialized)'                   >> "$gSSDT"
  echo '    {'                                                                            >> "$gSSDT"
  _getDSM true
}

#===============================================================================##
## GRAB DEVICE ADDRESS #
##==============================================================================##
function _getDevice_ACPI_Path()
{
  DEVICE=$1
  NEWDEVICE=$2
  PROP='acpi-path'
  SSDTADR=$(ioreg -p IODeviceTree -n "$DEVICE" -k $PROP | grep $PROP |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/acpipathlane//g; y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
  _checkDevice_Prop "${SSDTADR}" "$DEVICE" "$PROP"

  if [ ! -z "$NEWDEVICE" ];
    then
      echo '    Device ('${gSSDTPath}'.'${NEWDEVICE}')'                                   >> "$gSSDT"
    else
      echo '    Device ('${gSSDTPath}'.'${DEVICE}')'                                      >> "$gSSDT"
  fi
  echo '    {'                                                                            >> "$gSSDT"
  echo '        Name (_ADR, 0x'${SSDTADR}')  // _ADR: Address'                            >> "$gSSDT"
  _getDSM
}

#===============================================================================##
## CHECKS WHAT KIND OF METHOD: DSM OR DEVICE #
##==============================================================================##
function _buildSSDT()
{
  SSDT=$1

  if [[ "$SSDT" == "ALZA" ]];
    then
      # ****need to switch HDEF to ALZA ****
      #_getDevice_ACPI_Path "HDEF"
      _getDevice_ACPI_Path "${SSDT}" "HDEF"
      _setDeviceProp '"model"' '"Realtek Audio Controller"'
      _setDeviceProp '"hda-gfx"' '"onboard-1"'
      _setDeviceProp '"layout-id"' '0x01, 0x00, 0x00, 0x00'
      _setDeviceProp '"PinConfigurations"' '0x00'
      _findDeviceProp 'compatible' 'IOName'
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "EVMR" ]];
    then
      # ****need to switch SPSR to EVMR ****
      #_getDevice_ACPI_Path "SPSR"
      _getDevice_ACPI_Path "${SSDT}" "SPSR"
      _setDeviceProp '"AAPL,slot-name"' '"Built In"'
      _setDeviceProp '"device_type"' '"Intel SPSR Controller"'
      _setDeviceProp '"name"' '"C610/X99 Series Chipset SPSR"'
      _setDeviceProp '"model"' '"Intel SPSR Chipset"'
      _findDeviceProp 'device-id'
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "EVSS" ]];
    then
      _getExtDevice_Address $SSDT
      _setDeviceProp '"AAPL,slot-name"' '"Built In"'
      _setDeviceProp '"built-in"' '0x00'
      _setDeviceProp '"name"' '"Intel sSata Controller"'
      _setDeviceProp '"model"' '"Intel 99 Series Chipset Family sSATA Controller"'
      _setDeviceProp '"device_type"' '"AHCI Controller"'
      _findDeviceProp 'compatible' 'IOName'
      _findDeviceProp 'device-id'
      _close_Brackets
  fi

  if [[ "$SSDT" == "GFX1" ]];
    then
      _findGPU
      _setDeviceProp '"hda-gfx"' '"onboard-2"'
      _setDeviceProp '"@0,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDeviceProp '"@1,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDeviceProp '"@2,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDeviceProp '"@3,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDeviceProp '"@4,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDeviceProp '"@5,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _close_Brackets
      _findAUDIO
      _setDeviceProp '"hda-gfx"' '"onboard-2"'
      _findDeviceProp 'device-id'
      _close_Brackets
      _setGPUDevice_Status
  fi

  if [[ "$SSDT" == "GLAN" ]];
    then
      _getExtDevice_Address $SSDT
      _setDeviceProp '"model"' '"Intel i218V"'
      _setDeviceProp '"name"' '"Ethernet Controller"'
      _setDeviceProp '"built-in"' '0x00'
      _findDeviceProp 'device-id'
      _findDeviceProp 'subsystem-id'
      _findDeviceProp 'subsystem-vendor-id'
      _close_Brackets
  fi

  if [[ "$SSDT" == "HECI" ]];
    then
      # ****need to switch IMEI to HECI ****
      #_getDevice_ACPI_Path "IMEI"
      _getDevice_ACPI_Path "${SSDT}" "IMEI"
      _setDeviceProp '"AAPL,slot-name"' '"Built In"'
      _setDeviceProp '"model"' '"IMEI Controller"'
      _setDeviceProp '"built-in"' '0x00'
      _setDeviceProp '"compatible"' '"pci8086,1e3a"'
      _setDeviceProp '"device-id"' '0x3A, 0x1E, 0x00, 0x00'
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "LPC0" ]];
    then
      _getExtDevice_Address $SSDT
      _setDeviceProp '"compatible"' '"pci8086,9c43"'
      _close_Brackets
  fi

  if [[ "$SSDT" == "SAT1" ]];
    then
      _getExtDevice_Address $SSDT
      _setDeviceProp '"AAPL,slot-name"' '"Built In"'
      _setDeviceProp '"built-in"' '0x00'
      _setDeviceProp '"device-type"' '"AHCI Controller"'
      _setDeviceProp '"name"' '"Intel AHCI Controller"'
      _setDeviceProp '"model"' '"Intel 99 Series Chipset Family SATA Controller"'
      _findDeviceProp 'compatible' 'IOName'
      _findDeviceProp 'device-id'
      _close_Brackets
  fi

  if [[ "$SSDT" == "SMBS" ]];
    then
        # ****need to switch SBUS to SMBS ****
      _findDevice_Address $SSDT
      _findDeviceProp 'device-id'
      _close_Brackets true
      _setDevice_Status
  fi

  if [[ "$SSDT" == "XHC" ]];
    then
      _getExtDevice_Address $SSDT
      _setDeviceProp '"name"' '"Intel XHC Controller"'
      _setDeviceProp '"model"' '"Intel 99 Series Chipset Family USB xHC Host Controller"'
      _setDevice_NoBuffer '"AAPL,current-available"' '0x0834'
      _setDevice_NoBuffer '"AAPL,current-extra"' '0x0A8C'
      _setDevice_NoBuffer '"AAPL,current-in-sleep"' '0x0A8C'
      _setDevice_NoBuffer '"AAPL,max-port-current-in-sleep"' '0x0834'
      _setDevice_NoBuffer '"AAPL,device-internal"' '0x00'
      echo '                Buffer()'                                                     >> "$gSSDT"
      echo '                {'                                                            >> "$gSSDT"
      echo '                    0x00'                                                     >> "$gSSDT"
      echo '                },'                                                           >> "$gSSDT"
      _setDeviceProp '"AAPL,clock-id"' '0x01'
      _findDeviceProp 'device-id'
      _close_Brackets
  fi

  if [[ "$SSDT" == "XOSI" ]];
    then
      _getWindows_OSI
  fi
}

##===============================================================================##
# COMPILE SSDT AND CLEAN UP #
##===============================================================================##
function _compileSSDT
{
  ((gCount++))
  chown $gUSER $gSSDT
  printf "${STYLE_BOLD}Compiling:${STYLE_RESET} ${gSSDTID}.dsl\n"
  iasl -G "$gSSDT"
  printf "${STYLE_BOLD}Removing:${STYLE_RESET} ${gSSDTID}.dsl\n"
  printf  "\n%s" '--------------------------------------------------------------------------------'
  printf '\n'
  rm "$gSSDT"
  if [ ! -z "$buildOne" ];
    then
      echo "User only wanted to build ${buildOne}" > /dev/null 2>&1
      exit 0
  fi
  if [[ $gCount -lt 11 ]];
   then
      echo 'Attempting to build all SSDTs...' > /dev/null 2>&1
     _printHeader
  fi
}


##===============================================================================##
# PRINT FILE HEADER #
##===============================================================================##
function _printHeader()
{
  gSSDTID="SSDT-${gTableID[$gCount]}"
  printf 'Creating: '${gSSDTID}'.dsl \n'
  gSSDT="${gPath}/${gSSDTID}.dsl"

  echo '/*'                                                                               >  "$gSSDT"
  echo ' * Intel ACPI Component Architecture'                                             >> "$gSSDT"
  echo ' * AML/ASL+ Disassembler version 20161222-64(RM)'                                 >> "$gSSDT"
  echo ' * Copyright (c) 2000 - 2017 Intel Corporation'                                   >> "$gSSDT"
  echo ' * '                                                                              >> "$gSSDT"
  echo ' * Original Table Header:'                                                        >> "$gSSDT"
  echo ' *     Signature        "SSDT"'                                                   >> "$gSSDT"
  echo ' *     Length           '${gTableLength[$gCount]}''                               >> "$gSSDT"
  echo ' *     Revision         0x01'                                                     >> "$gSSDT"
  echo ' *     Checksum         '${gTableChecksum[$gCount]}''                             >> "$gSSDT"
  echo ' *     OEM ID           "mfc88"'                                                  >> "$gSSDT"
  echo ' *     OEM Table ID     "'${gTableID[$gCount]}'"'                                 >> "$gSSDT"
  echo ' *     OEM Revision     0x00000000 (0)'                                           >> "$gSSDT"
  echo ' *     Compiler ID      "INTL"'                                                   >> "$gSSDT"
  echo ' *     Compiler Version 0x20160422 (538313762)'                                   >> "$gSSDT"
  echo ' */'                                                                              >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo 'DefinitionBlock ("", "SSDT", 1, "mfc88", "'${gTableID[$gCount]}'", 0x00000000)'   >> "$gSSDT"
  echo '{'                                                                                >> "$gSSDT"
  _buildSSDT ${gTableID[$gCount]}
  _compileSSDT
}

##===============================================================================##
# CHECK USER CHOICES TO SSDT LIST #
##===============================================================================##
function _checkIfExists()
{
  for((i=0;i<=10;i++))
  do
  if [[ "${buildOne}" == "${gTableID[$i]}" ]];
    then
    gCount=$i
    _printHeader
    exit 0
  fi
  done

  echo ''
  echo "${bold}*—-ERROR—-*${normal} $buildOne is not a SSDT!"
  display_instructions
}

##===============================================================================##
# USER CHOOSES WHAT TO DO #
##===============================================================================##
function _user_choices()
{
  cr=`echo $'\n.'`
  cr=${cr%.}

  echo ''
  read -p "build all(${bold}-ba${normal}) | build a single SSDT(${bold}-b NAME${normal}) | debug(${bold}-d${normal}) | help(${bold}-h${normal}) | exit(${bold}-e${normal}) $cr" choice
    case "$choice" in
      # attempt to build all SSDTs
      -ba|-BA )
      main true
      exit 0
      ;;
      # attempt to build one SSDT
      -b* | -B*)
      buildOne=${choice:3:5}
       _checkIfExists
       exit
      ;;
      # debug mode
      -d|-D )
      set -x
      main true 2>&1 | tee "$dPath"
      ioreg >> "$dPath"
      set +x
      exit 0
      ;;
      # display help instructions
      -h|-H )
      display_instructions
      ;;
      # kill the script
      -e|-E )
      printf "\n"
      printf "Script was aborted!\033[0K\r\n"
      printf "\n"
      exit 0
      ;;
      # oops - user made a mistake, reload script
      * )
      printf "\n"
      printf "${bold}*—-ERROR—-*${normal} That was not a valid option!"
      printf "\n"
      display_instructions
      ;;
    esac
}

#===============================================================================##
## GREET USER #
##==============================================================================##
function greet()
{
  printf '            ssdtGen Version 0.0.7b - Copyright (c) 2017 by M.F.C.'
  printf  "\n%s" '--------------------------------------------------------------------------------'
  printf ' \n'
  sleep 0.25
}

#===============================================================================##
## CHECK USER'S MOTHERBOARD #
##==============================================================================##
function _checkBoard
{
  moboID=$(ioreg -lw0 -p IODeviceTree | awk '/OEMBoard/ {print $4}' | tr -d '<"">')
  moboID=${moboID:0:3}

  if [[ "$moboID" != "X99" ]];
    then
    printf "\n"
    printf "${bold}*—-ERROR—-*${normal} This script only supports X99 motherboards at the moment!\n"
    printf "\n"
    sleep 1
    printf "Script was aborted!\033[0K\r\n"
    printf "\n"
    exit 0
  fi
}

#===============================================================================##
## START PROGRAM #
##==============================================================================##
function main()
{
  local userChosen=$1

  clear
  greet
  _checkBoard
  if [ -z "$userChosen" ];
    then
      _user_choices
  fi
  _getSIPStat
  _checkPreInstalled
  _printHeader
}

trap '{ _clean_up; exit 1; }' INT

if [[ `id -u` -ne 0 ]];
  then
    printf "This script must be run as ROOT!\n"
    sudo "$0"
  else
    main
    exit 0
fi
