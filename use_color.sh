#!/bin/bash

source use_color.incl

echo -e "$bg_purple purple $bg_cyan cyan $bg_white white $bg_lightcyan lightcyan $bg_lightpurple lightpurple $bg_darkgray darkgray $_NC"
echo -e "$bg_red red $bg_green green $bg_lightred lightred $bg_lightgreen lightgreen $bg_blue blue $bg_lightgray lightgray $_NC"
echo -e "$bg_yellow yellow $bg_black black $bg_lightblue lightblue $bg_brown brown$_NC"
echo ""
echo ""
echo -e "$bg_lightblue Information $_NC"
echo ""
echo -e "$bg_lightgreen Normal $_NC"
echo ""
echo -e "$bg_brown Warning $_NC"
echo ""
echo -e "$bg_lightred Failure $_NC"
echo ""
echo -e "$fg_green AOK $_NC"
echo ""
echo ""
#  both bg and fg
#  cntl+v esc = ^[
echo -e "[0;31;40m In Color $_NC"
echo -e "\033[0;31;40m In Color $_NC"
echo ""
echo -e "$yellow_on_green yellow on green $_NC"
echo -e "$white_on_red white on red $_NC"
echo -e "$black_on_red black on red $_NC"
echo -e "$yellow_on_red yellow on red $_NC"
echo -e "$red_on_black red on black $_NC"
echo -e "$yellow_on_black yellow on black $_NC"
echo -e "$green_on_black green on black $_NC"
echo -e "$green2_on_black green on black $_NC"
