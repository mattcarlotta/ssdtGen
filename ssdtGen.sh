#===============================================================================##
## GLOBAL VARIABLES #
##==============================================================================##

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

gMaciASL="$HOME/Applications/MaciASL.app"

#IASL compiler directory
gIasl="$HOME/Documents/iasl.git"

#MaciASL and IASL download directories
gRehabmanMaciASL="https://bitbucket.org/RehabMan/os-x-maciasl-patchmatic/downloads/RehabMan-MaciASL-2017-0117.zip"
gRehabmanIASL="https://github.com/RehabMan/Intel-iasl.git"

#MaciASL file needed to be unzipped
gMaciASLFile="RehabMan-MaciASL-2017-0117.zip"

# User's Document directory
gDirectory="$HOME/Documents"

#Count to cycle thru arrays
gCount=0

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
  rm "${gPath}"/*.dsl
  sleep 1
  printf "Script was aborted!\033[0K\r\n"
  exit 1
  clear
}

#===============================================================================##
## CHECK SIP #
##==============================================================================##
function _getSIPStat()
{
  case "$(/usr/bin/csrutil status)" in
    "System Integrity Protection status: enabled." )
      printf 'ERROR! S.I.P is enabled, aborting...\n'
      printf 'Please disable S.I.P. by setting CsrActiveConfig to 0x67 in your config.plist!\n'
      exit 1
      ;;

    *"Kext Signing: enabled"* )
      printf 'ERROR! S.I.P. is partially disabled, but kext signing is still enabled, aborting...\n'
      printf 'Please completely disable S.I.P. by setting CsrActiveConfig to 0x67 in your config.plist!\n'
      exit 1
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
  if [ -x "/Applications/MaciASL.app" ];
    then
      echo 'MaciASL is already installed!' > /dev/null 2>&1
    else
      printf "*—-ERROR—-* MaciASL isn't installed in the $HOME/Applications directory!\n"
      printf " \n"
      printf "Attempting to download MaciASL from Rehabman's Bitbucket...\n"
      cd "$gDirectory"
      curl --silent -O -L $gRehabmanMaciASL
      if [[ $? -ne 0 ]];
        then
          printf ' \n'
          printf 'ERROR! Make sure your network connection is active and/or make sure you have already installed Xcode from the App store!\n'
          exit 1
      fi
      printf " \n"
      printf "Installing MaciASL to /Applications...\n"
      unzip -qu $gMaciASLFile
      mv "$gDirectory/MaciASL.app" /Applications
      rm $gMaciASLFile
      printf " \n"
      printf "MaciASL has been installed!\n"
      printf " \n"
  fi

  if [ ! -d "$HOME/Documents/iasl.git" ];
    then
      printf "*—-ERROR—-* IASL isn't installed in the $HOME/Documents!\n"
      printf " \n"
      printf "Attempting to download IASL from Rehabman's Github...\n"
      cd "$gDirectory"
      git clone $gRehabmanIASL iasl.git
      if [[ $? -ne 0 ]];
        then
          printf ' \n'
          printf 'ERROR! Make sure your network connection is active and/or make sure you have already installed Xcode from the App store!\n'
          exit 1
      fi
      cd iasl.git
      make
      make install
      cp /usr/bin/iasl /Applications/MaciASL.app/Contents/MacOS/iasl61
    else
      echo 'IASL is already installed!' > /dev/null 2>&1
  fi
}

#===============================================================================##
## CHECK DEVICE PROP IS NOT EMPTY #
##==============================================================================##
function _checkDevice_Prop()
{
  SSDT_PROP=$1
  SSDT_DEVICE=$2
  SSDT_KEY=$3

  if [ -z "$SSDT_PROP" ]
    then
      echo ''
      echo "*—-ERROR—-* There was a problem locating $SSDT_DEVICE's $SSDT_KEY! Please send an IOReg dump and a report of this error!"
      echo ''
      _clean_up
  fi
}

#===============================================================================##
## EOF BRACKETS #
##==============================================================================##
function _close_Brackets()
{
  MB=$1

  echo '            })'                                                                   >> "$gSSDT"
  echo '        }'                                                                        >> "$gSSDT"
  echo '    }'                                                                            >> "$gSSDT"

  if [ "$MB" = true ];
    then
    echo '   }'                                                                           >> "$gSSDT"
    echo '  }'                                                                            >> "$gSSDT"
  fi
}

#===============================================================================##
## EOF BRACKETS #
##==============================================================================##
function _getPowerOptions()
{
  echo ''                                                                                 >> "$gSSDT"
  echo '                "AAPL,current-available",'                                        >> "$gSSDT"
  echo '                0x0834,'                                                          >> "$gSSDT"
  echo '                "AAPL,current-extra",'                                            >> "$gSSDT"
  echo '                0x0A8C,'                                                          >> "$gSSDT"
  echo '                "AAPL,current-in-sleep",'                                         >> "$gSSDT"
  echo '                0x0A8C,'                                                          >> "$gSSDT"
  echo '                "AAPL,max-port-current-in-sleep",'                                >> "$gSSDT"
  echo '                0x0834,'                                                          >> "$gSSDT"
  echo '                "AAPL,device-internal",'                                          >> "$gSSDT"
  echo '                0x00,'                                                            >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00'                                                         >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "AAPL,clock-id",'                                                 >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x01'                                                         >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
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
## GRAB PIN CONFIG #
##==============================================================================##
function _getDevice_BuiltIn()
{
  SSDT_NAME=$1

  echo ''                                                                                 >> "$gSSDT"
  echo '                "built-in",'                                                      >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00'                                                         >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB PIN CONFIG #
##==============================================================================##
function _getDevice_PinConfig()
{
  SSDT_NAME=$1

  echo ''                                                                                 >> "$gSSDT"
  echo '                "PinConfigurations",'                                             >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00'                                                         >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB DEVICE NAME #
##==============================================================================##
function _getDevice_Name()
{
  SSDT_NAME=$1

  echo ''                                                                                 >> "$gSSDT"
  echo '                "name",'                                                          >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    '${SSDT_NAME}''                                               >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB DEVICE-TYPE #
##==============================================================================##
function _getDevice_Type()
{
  SSDT_DEV_TYPE=$1

  echo ''                                                                                 >> "$gSSDT"
  echo '                "device_type",'                                                   >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    '${SSDT_DEV_TYPE}''                                           >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB APPLE SLOT NAME #
##==============================================================================##
function _getDevice_SlotName()
{
  echo ''                                                                                 >> "$gSSDT"
  echo '                "AAPL,slot-name",'                                                >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "Built In"'                                                   >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB LAYOUT ID #
##==============================================================================##
function _getDevice_LayoutID()
{
  echo ''                                                                                 >> "$gSSDT"
  echo '                "layout-id",'                                                     >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x01, 0x00, 0x00, 0x00'                                       >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB HDA-GFX #
##==============================================================================##
function _getDevice_HdaGfx()
{
  option=$1

  echo ''                                                                                 >> "$gSSDT"
  echo '                "hda-gfx",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "onboard-'${option}'"'                                        >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB GFX Card Statics #
##==============================================================================##
function _getDevice_GFXStaticOptions()
{
  echo ''                                                                                 >> "$gSSDT"
  echo '                "AAPL,slot-name",'                                                >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "Slot-1"'                                                     >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@2,AAPL,boot-display",'                                          >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x02'                                                         >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@0,name",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "NVDA,Display-A"'                                             >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@1,name",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "NVDA,Display-B"'                                             >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@2,name",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "NVDA,Display-C"'                                             >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@3,name",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "NVDA,Display-D"'                                             >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@4,name",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "NVDA,Display-E"'                                             >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@5,name",'                                                       >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "NVDA,Display-F"'                                             >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@0,connector-type",'                                             >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00, 0x08, 0x00, 0x00'                                       >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@1,connector-type",'                                             >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00, 0x08, 0x00, 0x00'                                       >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@2,connector-type",'                                             >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00, 0x08, 0x00, 0x00'                                       >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@3,connector-type",'                                             >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00, 0x08, 0x00, 0x00'                                       >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@4,connector-type",'                                             >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00, 0x08, 0x00, 0x00'                                       >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '                "@5,connector-type",'                                             >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00, 0x08, 0x00, 0x00'                                       >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB SUBSYSTEM VENDOR DEVICE ID #
##==============================================================================##
function _getDevice_SubSysVendor_ID()
{
  key='subsystem-vendor-id'
  SSDT_SSV_ID=$(ioreg -p IODeviceTree -n "$device" -k $key | grep $key |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/subsystemvendorid//g')
  _checkDevice_Prop "${SSDT_SSV_ID}" "$device" "$key"

  echo ''                                                                                 >> "$gSSDT"
  echo '                "subsystem-vendor-id",'                                           >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x'${SSDT_SSV_ID:0:2}', 0x'${SSDT_SSV_ID:2:2}', 0x00, 0x00'   >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB SUBSYSTEM DEVICE ID #
##==============================================================================##
function _getDevice_SubSys_ID()
{
  key='subsystem-id'
  SSDT_SUBSYS_ID=$(ioreg -p IODeviceTree -n "$device" -k $key | grep $key |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/subsystemid//g')
  _checkDevice_Prop "${SSDT_SUBSYS_ID}" "$device" "$key"

  echo ''                                                                                 >> "$gSSDT"
  echo '                "subsystem-id",'                                                  >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x00, 0x'${SSDT_SUBSYS_ID:2:2}', 0x00, 0x00'                  >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB DEVICE ID #
##==============================================================================##
function _getDevice_ID()
{
  key='device-id'
  SSDT_DEVID=$(ioreg -p IODeviceTree -n "$device" -k $key | grep $key |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/deviceid//g')
  _checkDevice_Prop "${SSDT_DEVID}" "$device" "$key"

  echo ''                                                                                 >> "$gSSDT"
  echo '                "device-id",'                                                     >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    0x'${SSDT_DEVID:0:2}', 0x'${SSDT_DEVID:2:2}', 0x00, 0x00'     >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB COMPATIBLE PCI ID #
##==============================================================================##
function _getDevice_CompatibleID()
{
  key='compatible'
  SSDT_COMPAT=$(ioreg -p IODeviceTree -n "$device" -k $key | grep $key |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/compatible//g')
  _checkDevice_Prop "${SSDT_COMPAT}" "$device" "$key"

  echo ''                                                                                 >> "$gSSDT"
  echo '                "compatible",'                                                    >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    "'$SSDT_COMPAT'"'                                             >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB COMPATIBLE PCI ID #
##==============================================================================##
function _getDevice_Model()
{
  SSDTMODEL=$1

  echo ''                                                                                 >> "$gSSDT"
  echo '                "model",'                                                         >> "$gSSDT"
  echo '                Buffer()'                                                         >> "$gSSDT"
  echo '                {'                                                                >> "$gSSDT"
  echo '                    '$SSDTMODEL''                                                 >> "$gSSDT"
  echo '                },'                                                               >> "$gSSDT"
}

#===============================================================================##
## GRAB LEqual _DSM #
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
  echo '            Return (Package ()'                                                   >> "$gSSDT"
  echo '            {'                                                                    >> "$gSSDT"
}

#===============================================================================##
## GRAB WINDOWS OSI  #
##==============================================================================##
function _getWindows_OSI()
{
  echo '    Method (XOSI, 1)'                   >> "$gSSDT"
  echo '    {'                                                                            >> "$gSSDT"
  echo '        Store(Package()'                                                          >> "$gSSDT"
  echo '        {'                                                                        >> "$gSSDT"
  echo '            "Windows",                // generic Windows query'                   >> "$gSSDT"
  echo '            "Windows 2001",           // Windows XP'                              >> "$gSSDT"
  echo '            "Windows 2001 SP2",       // Windows XP SP2'                          >> "$gSSDT"
  echo '             //"Windows 2001.1",      // Windows Server 2003'                     >> "$gSSDT"
  echo '            //"Windows 2001.1 SP1",   // Windows Server 2003 SP1'                 >> "$gSSDT"
  echo '            "Windows 2006",           // Windows Vista'                           >> "$gSSDT"
  echo '            "Windows 2006 SP1",       // Windows Vista SP1'                       >> "$gSSDT"
  echo '            //"Windows 2006.1",       // Windows Server 2008'                     >> "$gSSDT"
  echo '            "Windows 2009",           // Windows 7/Windows Server 2008 R2'        >> "$gSSDT"
  echo '            "Windows 2012",           // Windows 8/Windows Server 2012'           >> "$gSSDT"
  echo '            //"Windows 2013",         // Windows 8.1/Windows Server 2012 R2'      >> "$gSSDT"
  echo '            //"Windows 2015",         // Windows 10/Windows Server TP'            >> "$gSSDT"
  echo '        }, Local0)'                                                               >> "$gSSDT"
  echo '       Return (Ones != Match(Local0, MEQ, Arg0, MTR, 0, 0))'                      >> "$gSSDT"
  echo '    }'                                                                            >> "$gSSDT"
  echo '}'                                                                                >> "$gSSDT"
}

#===============================================================================##
## GRAB SMBS DEVICE  #
##==============================================================================##
function _getExtDevice_Address_SMBS()
{
  device='SBUS'
  key='acpi-path'
  SSDTADR=$(ioreg -p IODeviceTree -n "$device" -k $key | grep $key |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/acpipathlane//g; y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
  _testVariable "${SSDTADR}" "$device" "$key"

  echo '    Device ('${gSSDTPath}'.'${device}')'                                          >> "$gSSDT"
  echo '    {'                                                                            >> "$gSSDT"
  echo '        Name (_ADR, 0x'${SSDTADR}')  // _ADR: Address'                            >> "$gSSDT"
  echo '        Device (BUS0)'                                                            >> "$gSSDT"
  echo '        {'                                                                        >> "$gSSDT"
  echo '            Name (_CID, "smbus") // _CID: Compatible ID'                          >> "$gSSDT"
  echo '            Name (_ADR, Zero)'                                                    >> "$gSSDT"
  echo '            Device (DVL0)'                                                        >> "$gSSDT"
  echo '            {'                                                                    >> "$gSSDT"
  echo '                   Name (_ADR, 0x57)'                                             >> "$gSSDT"
  echo '                   Name (_CID, "diagsvault")'                                     >> "$gSSDT"
  _getDSM
}

#===============================================================================##
## GRAB EXTERNAL DEVICE ADDRESS #
##==============================================================================##
function _getExtDevice_Address()
{
  device=$1

  if [[ "$device" == 'XHC' ]];
    then
      local dash="_"
  fi
  
  echo '    External ('${gExtDSDTPath}'.'${device}''${dash}', DeviceObj)'                      >> "$gSSDT"
  echo ''                                                                                 >> "$gSSDT"
  echo '    Method ('${gSSDTPath}'.'${device}'._DSM, 4, NotSerialized)'                   >> "$gSSDT"
  echo '    {'                                                                            >> "$gSSDT"
  _getDSM true
}

#===============================================================================##
## GRAB DEVICE ADDRESS #
##==============================================================================##
function _getDevice_Address()
{
  device=$1
  key='acpi-path'
  SSDTADR=$(ioreg -p IODeviceTree -n "$device" -k $key | grep $key |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/acpipathlane//g; y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
  _testVariable "${SSDTADR}" "$device" "$key"

  echo '    Device ('${gSSDTPath}'.'${device}')'                                          >> "$gSSDT"
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

  if [[ "$SSDT" == 'ALZA' ]];
    then
      # ****need to switch HDEF to ALZA ****
      _getDevice_Address HDEF
      _getDevice_Model '"Realtek Audio Controller"'
      _getDevice_HdaGfx 1
      _getDevice_LayoutID
      _getDevice_CompatibleID $device
      _getDevice_PinConfig
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "EVMR" ]];
    then
      # ****need to switch SPSR to EVMR ****
      _getDevice_Address SPSR
      _getDevice_SlotName
      _getDevice_ID
      _getDevice_Type '"Intel SPSR Controller"'
      _getDevice_Name '"C610/X99 Series Chipset SPSR"'
      _getDevice_Model '"Intel SPSR Chipset"'
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "EVSS" ]];
    then
      _getExtDevice_Address EVSS
      _getDevice_SlotName
      _getDevice_BuiltIn
      _getDevice_Name '"Intel sSata Controller"'
      _getDevice_Model '"Intel 99 Series Chipset Family sSATA Controller"'
      _getDevice_CompatibleID $device
      _getDevice_Type '"AHCI Controller"'
      _getDevice_ID
      _close_Brackets
  fi

  # GFX1
  #if [[ "$SSDT" == "GFX1" ]];
    #then
  #_getDevice_GFXStaticOptions
  #_getDevice_HdaGfx 2
  #_getDevice_ID
  #_getDevice_Name '"Display"'

  if [[ "$SSDT" == "GLAN" ]];
    then
      _getExtDevice_Address GLAN
      _getDevice_Model '"Intel i218V"'
      _getDevice_Name '"Ethernet Controller"'
      _getDevice_BuiltIn
      _getDevice_ID
      _getDevice_SubSys_ID
      _getDevice_SubSysVendor_ID
      _close_Brackets
  fi

  if [[ "$SSDT" == "HECI" ]];
    then
        # ****need to switch IMEI to HECI ****
      _getDevice_Address IMEI
      _getDevice_SlotName
      _getDevice_Model '"IMEI Controller"'
      _getDevice_BuiltIn
      _getDevice_ID
      _getDevice_CompatibleID $device
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "LPC0" ]];
    then
      _getExtDevice_Address LPC0
      _getDevice_CompatibleID $device
      _close_Brackets
  fi

  if [[ "$SSDT" == "SAT1" ]];
    then
      _getExtDevice_Address SAT1
      _getDevice_SlotName
      _getDevice_BuiltIn
      _getDevice_Name '"Intel AHCI Controller"'
      _getDevice_Model '"Intel 99 Series Chipset Family SATA Controller"'
      _getDevice_CompatibleID $device
      _getDevice_Type '"AHCI Controller"'
      _getDevice_ID
      _close_Brackets
  fi

  if [[ "$SSDT" == "SMBS" ]];
    then
        # ****need to switch SBUS to SMBS ****
      _getExtDevice_Address_SMBS
      _getDevice_ID
      _close_Brackets true
      _setDevice_Status
  fi

  if [[ "$SSDT" == "XHC" ]];
    then
      _getExtDevice_Address XHC
      _getDevice_ID
      _getDevice_Name '"Intel XHC Controller"'
      _getDevice_Model '"Intel 99 Series Chipset Family USB xHC Host Controller"'
      _getPowerOptions
      _close_Brackets
  fi

  if [[ "$SSDT" == "XOSI" ]];
    then
      _getWindows_OSI
  fi
}

#===============================================================================##
## PRINT FILE HEADER #
##==============================================================================##
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

}

# #===============================================================================##
# ## COMPILE SSDT AND CLEAN UP #
# ##==============================================================================##
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
  if [[ $gCount -lt 11 ]];
   then
     _printHeader
     _compileSSDT
  fi
}

#===============================================================================##
## GREET USER #
##==============================================================================##
function greet()
{
  printf '            ssdtGen Version 0.0.1.b - Copyright (c) 2017 by M.F.C.'
  printf  "\n%s" '--------------------------------------------------------------------------------'
  printf ' \n'
  sleep 0.25
}

#===============================================================================##
## START PROGRAM #
##==============================================================================##
function main()
{
  clear
  greet
  _getSIPStat
  _checkPreInstalled
  _printHeader
  _compileSSDT
}

trap '{ _clean_up; exit 1; }' INT

if [[ `id -u` -ne 0 ]];
  then
    printf "This script must be run as ROOT!\n"
    sudo "$0"
  else
    main
fi

exit 0
