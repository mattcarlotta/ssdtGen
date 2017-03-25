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
  SSDT_VALUE=$1
  SSDT_DEVICE=$2
  SSDT_PROP=$3

  if [ -z "$SSDT_VALUE" ]
    then
      echo ''
      echo "*—-ERROR—-* There was a problem locating $SSDT_DEVICE's $SSDT_PROP! Please send an IORegistry dump and a report of this error!"
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
function _setDevice()
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
  SSDT_VALUE=$(ioreg -p IODeviceTree -n "$DEVICE" -k $PROP | grep $PROP |  sed -e 's/ *["|=<A-Z>:/_@]//g; s/'$PROP'//g')
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
  D0XX=$(ioreg -p IODeviceTree -n ${PCISLOT} -r | grep D0 | sed -e 's/ *["+|=<a-z>:/_@-]//g; s/^ *//g; s/(.{4}).{0}//g')
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
  echo '            Return (Package ()'                                                   >> "$gSSDT"
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
  DEVICE=${GPUPATH:4:4} #H000/GFX1
  GPU=$DEVICE
  echo $GPUPATH
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
 ## GRAB SMBS DEVICE  #
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

  if [[ "$DEVICE" == 'XHC' ]];
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
  PROP='acpi-path'
  SSDTADR=$(ioreg -p IODeviceTree -n "$DEVICE" -k $PROP | grep $PROP |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/acpipathlane//g; y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
  _checkDevice_Prop "${SSDTADR}" "$DEVICE" "$PROP"

  echo '    Device ('${gSSDTPath}'.'${DEVICE}')'                                          >> "$gSSDT"
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
      _getDevice_ACPI_Path $SSDT
      _setDevice '"model"' '"Realtek Audio Controller"'
      _setDevice '"hda-gfx"' '"onboard-1"'
      _setDevice '"layout-id"' '0x01, 0x00, 0x00, 0x00'
      _setDevice '"PinConfigurations"' '0x00'
      _findDeviceProp 'compatible'
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "EVMR" ]];
    then
      # ****need to switch SPSR to EVMR ****
      _getDevice_ACPI_Path $SSDT
      _setDevice '"AAPL,slot-name"' '"Built In"'
      _setDevice '"device_type"' '"Intel SPSR Controller"'
      _setDevice '"name"' '"C610/X99 Series Chipset SPSR"'
      _setDevice '"model"' '"Intel SPSR Chipset"'
      _findDeviceProp 'device-id'
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "EVSS" ]];
    then
      _getExtDevice_Address $SSDT
      _setDevice '"AAPL,slot-name"' '"Built In"'
      _setDevice '"built-in"' '0x00'
      _setDevice '"name"' '"Intel sSata Controller"'
      _setDevice '"model"' '"Intel 99 Series Chipset Family sSATA Controller"'
      _setDevice '"device_type"' '"AHCI Controller"'
      _findDeviceProp 'compatible'
      _findDeviceProp 'device-id'
      _close_Brackets
  fi

  if [[ "$SSDT" == "GFX1" ]];
    then
      _findGPU
      _setDevice '"name"' '"Display"'
      _setDevice '"model"' '"NVIDIA GeForce GTX"'
      _setDevice '"hda-gfx"' '"onboard-2"'
      _setDevice '"AAPL,slot-name"' '"Slot-1"'
      _setDevice '"@2,AAPL,boot-display"' '0x02'
      _setDevice '"@0,name"' '"NVDA,Display-A"'
      _setDevice '"@1,name"' '"NVDA,Display-B"'
      _setDevice '"@2,name"' '"NVDA,Display-C"'
      _setDevice '"@3,name"' '"NVDA,Display-D"'
      _setDevice '"@4,name"' '"NVDA,Display-E"'
      _setDevice '"@5,name"' '"NVDA,Display-F"'
      _setDevice '"@0,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDevice '"@1,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDevice '"@2,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDevice '"@3,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDevice '"@4,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _setDevice '"@5,connector-type"' '0x00, 0x08, 0x00, 0x00'
      _findDeviceProp 'device-id'
      _close_Brackets
      _findAUDIO
      _setDevice '"name"' '"HD Audio"'
      _setDevice '"hda-gfx"' '"onboard-2"'
      _setDevice '"AAPL,slot-name"' '"Slot-1"'
      _setDevice '"built-in"' '0x00'
      _setDevice '"device-type"' '"HDMI AUDIO"'
      _findDeviceProp 'device-id'
      _close_Brackets
      _setGPUDevice_Status
  fi

  if [[ "$SSDT" == "GLAN" ]];
    then
      _getExtDevice_Address $SSDT
      _setDevice '"model"' '"Intel i218V"'
      _setDevice '"name"' '"Ethernet Controller"'
      _setDevice '"built-in"' '0x00'
      _findDeviceProp 'device-id'
      _findDeviceProp 'subsystem-id'
      _findDeviceProp 'subsystem-vendor-id'
      _close_Brackets
  fi

  if [[ "$SSDT" == "HECI" ]];
    then
        # ****need to switch IMEI to HECI ****
      _getDevice_ACPI_Path $SSDT
      _setDevice '"AAPL,slot-name"' '"Built In"'
      _setDevice '"model"' '"IMEI Controller"'
      _setDevice '"built-in"' '0x00'
      _findDeviceProp 'compatible'
      _findDeviceProp 'device-id'
      _close_Brackets
      _setDevice_Status
  fi

  if [[ "$SSDT" == "LPC0" ]];
    then
      _getExtDevice_Address $SSDT
      _findDeviceProp 'compatible'
      _close_Brackets
  fi

  if [[ "$SSDT" == "SAT1" ]];
    then
      _getExtDevice_Address $SSDT
      _setDevice '"AAPL,slot-name"' '"Built In"'
      _setDevice '"built-in"' '0x00'
      _setDevice '"device-type"' '"AHCI Controller"'
      _setDevice '"name"' '"Intel AHCI Controller"'
      _setDevice '"model"' '"Intel 99 Series Chipset Family SATA Controller"'
      _findDeviceProp 'compatible'
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
      _setDevice '"name"' '"Intel XHC Controller"'
      _setDevice '"model"' '"Intel 99 Series Chipset Family USB xHC Host Controller"'
      _setDevice_NoBuffer '"AAPL,current-available"' '0x0834'
      _setDevice_NoBuffer '"AAPL,current-extra"' '0x0A8C'
      _setDevice_NoBuffer '"AAPL,current-in-sleep"' '0x0A8C'
      _setDevice_NoBuffer '"AAPL,max-port-current-in-sleep"' '0x0834'
      _setDevice_NoBuffer '"AAPL,device-internal"' '0x00'
      echo '                Buffer()'                                                     >> "$gSSDT"
      echo '                {'                                                            >> "$gSSDT"
      echo '                    0x00'                                                     >> "$gSSDT"
      echo '                },'                                                           >> "$gSSDT"
      _setDevice '"AAPL,clock-id"' '0x01'
      _findDeviceProp 'device-id'
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
