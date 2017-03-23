gPath="$HOME/Desktop"
gSSDT=""
gSSDTID=""
gUSER=$(stat -f%Su /dev/console)
gIasl="$HOME/Documents/iasl.git"

# ALZA, Length  0x000000ED (237), Checksum 0xBC, Device
# EVMR, Length  0x00000108 (264), Checksum 0x5F, Device
# EVSS, Length  0x0000013A (314), Checksum 0x02, _DSM
# GFX1, Length  0x0000037C (892), Checksum 0x89, Device
# GLAN, Length  0x000000E6 (230), Checksum 0x53, _DSM
# HECI, Length  0x000000FE (254), Checksum 0x78, Device
# LCP0, Length  0x00000078 (120), Checksum 0x11, _DSM
# SAT1, Length  0x00000138 (312), Checksum 0x9E, _DSM
# SMBS, Length  0x000000B6 (182), Checksum 0x7F, Device
#===============================================================================##
## USER ABORTS SCRIPT #
##==============================================================================##
function _clean_up() {
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
## PRINT FILE HEADER #
##==============================================================================##
function _printHeader()
{
    _getTables
    gSSDTID="SSDT-$tableID"
    gSSDT="${gPath}/${gSSDTID}.dsl"

    echo '/*'                                                                               >  "$gSSDT"
    echo ' * Intel ACPI Component Architecture'                                             >> "$gSSDT"
    echo ' * AML/ASL+ Disassembler version 20161222-64(RM)'                                 >> "$gSSDT"
    echo ' * Copyright (c) 2000 - 2017 Intel Corporation'                                   >> "$gSSDT"
    echo ' * '                                                                              >> "$gSSDT"
    echo ' * Original Table Header:'                                                        >> "$gSSDT"
    echo ' *     Signature        "SSDT"'                                                   >> "$gSSDT"
    echo ' *     Length           '${tableLength}''                                         >> "$gSSDT"
    echo ' *     Revision         0x01'                                                     >> "$gSSDT"
    echo ' *     Checksum         '$tableChecksum''                                         >> "$gSSDT"
    echo ' *     OEM ID           "mfc88"'                                                  >> "$gSSDT"
    echo ' *     OEM Table ID     "'$tableID'"'                                             >> "$gSSDT"
    echo ' *     OEM Revision     0x00000000 (0)'                                           >> "$gSSDT"
    echo ' *     Compiler ID      "INTL"'                                                   >> "$gSSDT"
    echo ' *     Compiler Version 0x20160422 (538313762)'                                   >> "$gSSDT"
    echo ' */'                                                                              >> "$gSSDT"
    echo ''                                                                                 >> "$gSSDT"
    echo 'DefinitionBlock ("", "SSDT", 1, "mfc88", "'$tableID'", 0x00000000)'               >> "$gSSDT"
    echo '{'                                                                                >> "$gSSDT"
}

#===============================================================================##
## GET SSDT TABLES #
##==============================================================================##
function _getTables
{
  tableID='ALZA'
  tableLength="0x000000ED (237)"
  tableChecksum='0xBC'
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
  _printHeader
  chown $gUSER $gSSDT
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
