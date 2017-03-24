gPath="$HOME/Desktop"
gSSDT=""
gSSDTID=""
gUSER=$(stat -f%Su /dev/console)
gIasl="$HOME/Documents/iasl.git"
gCount=0
gTableID=(
[0]='ALZA'
[1]='EVMR'
[2]='EVSS'
[3]='GFX1'
[4]='GLAN'
[5]='HECI'
[6]='LCP0'
[7]='SAT1'
[8]='SMBS'
[9]='XHC'
[10]='XOSI'
)
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
# 10 XOIS,Length  0x000000B0 (176), Checksum 0xA2, Special

#===============================================================================##
## USER ABORTS SCRIPT #
##==============================================================================##
function _clean_up()
{
  printf "User aborted! Cleaning up script...\033[0K\r\n"
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
## GRAB GENERIC _DSM #
##==============================================================================##
function _getDSM()
{
  echo '        Method (_DSM, 4, NotSerialized)'                                          >> "$gSSDT"
  echo '        {'                                                                        >> "$gSSDT"
  echo '            If (LEqual (Arg2, Zero))'                                             >> "$gSSDT"
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
## CHECKS WHAT KIND OF METHOD: DSM OR DEVICE #
##==============================================================================##
function _check_SSDTMethod()
{
  SSDT=$1
  # ****need to switch HDEF to ALZA ****
SSDTADR=$(ioreg -p IODeviceTree -n "HDEF" -k acpi-path | grep acpi-path |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/acpipathlane//g; y/abcdefghijklmnopqrstuvwxyz/ABCDEFGHIJKLMNOPQRSTUVWXYZ/')
SSDTCOMPAT=$(ioreg -p IODeviceTree -n "HDEF@1B" -k compatible | grep compatible |  sed -e 's/ *["|=<A-Z>:/_@-]//g; s/compatible//g')

  if [[ $SSDT -eq 'ALZA' ]];
    then
      echo '    Device (_SB.PCI0.HDEF)'                                                   >> "$gSSDT"
      echo '    {'                                                                        >> "$gSSDT"
      echo '        Name (_ADR, 0x'${SSDTADR}')  // _ADR: Address'                        >> "$gSSDT"
      _getDSM
      echo '                "model",'                                                     >> "$gSSDT"
      echo '                Buffer()'                                                     >> "$gSSDT"
      echo '                {'                                                            >> "$gSSDT"
      echo '                    "Realtek Audio Controller"'                               >> "$gSSDT"
      echo '                },'                                                           >> "$gSSDT"
      echo ''                                                                             >> "$gSSDT"
      echo '                "hda-gfx",'                                                   >> "$gSSDT"
      echo '                Buffer()'                                                     >> "$gSSDT"
      echo '                {'                                                            >> "$gSSDT"
      echo '                    "onboard-1"'                                              >> "$gSSDT"
      echo '                },'                                                           >> "$gSSDT"
      echo ''                                                                             >> "$gSSDT"
      echo '                "layout-id",'                                                 >> "$gSSDT"
      echo '                Buffer()'                                                     >> "$gSSDT"
      echo '                {'                                                            >> "$gSSDT"
      echo '                    0x01, 0x00, 0x00, 0x00'                                   >> "$gSSDT"
      echo '                },'                                                           >> "$gSSDT"
      echo ''                                                                             >> "$gSSDT"
      echo '                "compatible",'                                                >> "$gSSDT"
      echo '                Buffer()'                                                     >> "$gSSDT"
      echo '                {'                                                            >> "$gSSDT"
      echo '                  "'$SSDTCOMPAT'"'                                            >> "$gSSDT"
      echo '                },'                                                           >> "$gSSDT"
      echo ''                                                                             >> "$gSSDT"
      echo '                "PinConfiguration",'                                          >> "$gSSDT"
      echo '                Buffer()'                                                     >> "$gSSDT"
      echo '                {'                                                            >> "$gSSDT"
      echo '                    0x00'                                                     >> "$gSSDT"
      echo '                }'                                                            >> "$gSSDT"
      echo '            })'                                                               >> "$gSSDT"
      echo '        }'                                                                    >> "$gSSDT"
      echo '    }'                                                                        >> "$gSSDT"
      echo ''                                                                             >> "$gSSDT"
      echo '    Name (_SB.PCI0.ALZA._STA, Zero)  // _STA: Status'                         >> "$gSSDT"
      echo '}'                                                                            >> "$gSSDT"
  fi
}

#===============================================================================##
## PRINT FILE HEADER #
##==============================================================================##
function _printHeader()
{
    gSSDTID="SSDT-${gTableID[$gCount]}"
    echo $gSSDTID
    gSSDT="${gPath}/${gSSDTID}.dsl"

    echo '/*'                                                                             >  "$gSSDT"
    echo ' * Intel ACPI Component Architecture'                                           >> "$gSSDT"
    echo ' * AML/ASL+ Disassembler version 20161222-64(RM)'                               >> "$gSSDT"
    echo ' * Copyright (c) 2000 - 2017 Intel Corporation'                                 >> "$gSSDT"
    echo ' * '                                                                            >> "$gSSDT"
    echo ' * Original Table Header:'                                                      >> "$gSSDT"
    echo ' *     Signature        "SSDT"'                                                 >> "$gSSDT"
    echo ' *     Length           '${gTableLength[$gCount]}''                             >> "$gSSDT"
    echo ' *     Revision         0x01'                                                   >> "$gSSDT"
    echo ' *     Checksum         '${gTableChecksum[$gCount]}''                           >> "$gSSDT"
    echo ' *     OEM ID           "mfc88"'                                                >> "$gSSDT"
    echo ' *     OEM Table ID     "'${gTableID[$gCount]}'"'                               >> "$gSSDT"
    echo ' *     OEM Revision     0x00000000 (0)'                                         >> "$gSSDT"
    echo ' *     Compiler ID      "INTL"'                                                 >> "$gSSDT"
    echo ' *     Compiler Version 0x20160422 (538313762)'                                 >> "$gSSDT"
    echo ' */'                                                                            >> "$gSSDT"
    echo ''                                                                               >> "$gSSDT"
    echo 'DefinitionBlock ("", "SSDT", 1, "mfc88", "'${gTableID[$gCount]}'", 0x00000000)' >> "$gSSDT"
    echo '{'                                                                              >> "$gSSDT"

    _check_SSDTMethod ${gTableID[$gCount]}
}

# #===============================================================================##
# ## GET SSDT TABLES #
# ##==============================================================================##
# function _getTables
# {
#
#
# }

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
  _printHeader
  #chown $gUSER $gSSDT
  #printf "\n${STYLE_BOLD}Compiling:${STYLE_RESET} ${gSSDT}"
  #iasl -G "$gSSDT"
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
