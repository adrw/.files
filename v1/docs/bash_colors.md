## Bash Color

Source: https://stackoverflow.com/questions/5947742/how-to-change-the-output-color-of-echo-in-linux

Usage
echo "$(tput setaf 1)Red text$(tput setab 7)and white background\$(tput sgr 0)"

Foreground & background colour commands
tput setab [1-7] # Set the background colour using ANSI escape
tput setaf [1-7] # Set the foreground colour using ANSI escape

Num Colour #define R G B

0 black COLOR_BLACK 0,0,0
1 red COLOR_RED 1,0,0
2 green COLOR_GREEN 0,1,0
3 yellow COLOR_YELLOW 1,1,0
4 blue COLOR_BLUE 0,0,1
5 magenta COLOR_MAGENTA 1,0,1
6 cyan COLOR_CYAN 0,1,1
7 white COLOR_WHITE 1,1,1

Text mode commands

tput bold # Select bold mode
tput dim # Select dim (half-bright) mode
tput smul # Enable underline mode
tput rmul # Disable underline mode
tput rev # Turn on reverse video mode
tput smso # Enter standout (bold) mode
tput rmso # Exit standout mode

Cursor movement commands

tput cup Y X # Move cursor to screen postion X,Y (top left is 0,0)
tput cuf N # Move N characters forward (right)
tput cub N # Move N characters back (left)
tput cuu N # Move N lines up
tput ll # Move to last line, first column (if no cup)
tput sc # Save the cursor position
tput rc # Restore the cursor position
tput lines # Output the number of lines of the terminal
tput cols # Output the number of columns of the terminal

Clear and insert commands

tput ech N # Erase N characters
tput clear # Clear screen and move the cursor to 0,0
tput el 1 # Clear to beginning of line
tput el # Clear to end of line
tput ed # Clear to end of screen
tput ich N # Insert N characters (moves rest of line forward!)
tput il N # Insert N lines

Other commands

tput sgr0 # Reset text format to the terminal's default
tput bel # Play a bell

Scripts

tput accepts scripts containing one command per line, which are executed in order before tput exits.

Avoid temporary files by echoing a multiline string and piping it:
echo -e "setf 7\nsetb 1" | tput -S # set fg white and bg red

# Reset

Color_Off='\033[0m' # Text Reset

# Regular Colors

Black='\033[0;30m' # Black
Red='\033[0;31m' # Red
Green='\033[0;32m' # Green
Yellow='\033[0;33m' # Yellow
Blue='\033[0;34m' # Blue
Purple='\033[0;35m' # Purple
Cyan='\033[0;36m' # Cyan
White='\033[0;37m' # White

# Bold

BBlack='\033[1;30m' # Black
BRed='\033[1;31m' # Red
BGreen='\033[1;32m' # Green
BYellow='\033[1;33m' # Yellow
BBlue='\033[1;34m' # Blue
BPurple='\033[1;35m' # Purple
BCyan='\033[1;36m' # Cyan
BWhite='\033[1;37m' # White

# Underline

UBlack='\033[4;30m' # Black
URed='\033[4;31m' # Red
UGreen='\033[4;32m' # Green
UYellow='\033[4;33m' # Yellow
UBlue='\033[4;34m' # Blue
UPurple='\033[4;35m' # Purple
UCyan='\033[4;36m' # Cyan
UWhite='\033[4;37m' # White

# Background

On_Black='\033[40m' # Black
On_Red='\033[41m' # Red
On_Green='\033[42m' # Green
On_Yellow='\033[43m' # Yellow
On_Blue='\033[44m' # Blue
On_Purple='\033[45m' # Purple
On_Cyan='\033[46m' # Cyan
On_White='\033[47m' # White

# High Intensity

IBlack='\033[0;90m' # Black
IRed='\033[0;91m' # Red
IGreen='\033[0;92m' # Green
IYellow='\033[0;93m' # Yellow
IBlue='\033[0;94m' # Blue
IPurple='\033[0;95m' # Purple
ICyan='\033[0;96m' # Cyan
IWhite='\033[0;97m' # White

# Bold High Intensity

BIBlack='\033[1;90m' # Black
BIRed='\033[1;91m' # Red
BIGreen='\033[1;92m' # Green
BIYellow='\033[1;93m' # Yellow
BIBlue='\033[1;94m' # Blue
BIPurple='\033[1;95m' # Purple
BICyan='\033[1;96m' # Cyan
BIWhite='\033[1;97m' # White

# High Intensity backgrounds

On_IBlack='\033[0;100m' # Black
On_IRed='\033[0;101m' # Red
On_IGreen='\033[0;102m' # Green
On_IYellow='\033[0;103m' # Yellow
On_IBlue='\033[0;104m' # Blue
On_IPurple='\033[0;105m' # Purple
On_ICyan='\033[0;106m' # Cyan
On_IWhite='\033[0;107m' # White
