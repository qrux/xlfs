##################################################
#
# Global Aliases
#
##################################################

_SYSTEM=$(uname -s)

find_darwin_major ()
{
	echo $(uname -r | cut -d \. -f 1)
}

########################################################################
#
# Change flags for common commands based on `uname -s` ($_SYSTEM)
#
########################################################################

LANG="C"
LS_FLAGS="-F"
LS_COLORS=""
PS_FLAGS="aux"
PS_SUFFIX="sort"
DF_FLAGS="-h"

if [ "Darwin" = $_SYSTEM ] ; then
	if [ "xterm-256color" = $TERM ] ; then
                if [ "10" = $(find_darwin_major) ] ; then
                        echo "  Changing terminal-type to xterm-color."
                        TERM="xterm-color"
                        export TERM
                fi
	fi

	LANG="en_US.UTF-8"

	LS_FLAGS="-G -F"

	LSCOLORS="DxGxcxdxCxegedabagacad"

	PS_FLAGS="axo user,pid,vsz,rss,%mem,command -m"
	PS_SUFFIX="sed 's/\ *$//' | grep -v grep"

	DF_FLAGS="-Phl"
elif [ "Linux" = ${_SYSTEM} ] ; then
	LANG="C"

	LS_FLAGS="--color -F -N -T 0"
	LS_COLORS="di=1;93:fi=0:ln=1;36:pi=106:so=35:bd=1;33:cd=1;31:or=31:mi=0:ex=35:*.rpm=90"
	#if [ -z $LS_COLORS ] ; then
		#LS_COLORS="di=93"
	#else
		#LS_COLORS="$LS_COLORS:di=93"
	#fi

	PS_FLAGS="axo user,pid,vsz,rsz,%mem,cmd --sort=vsize"
	PS_SUFFIX="grep -v grep"
	DF_FLAGS="-h"
elif [ "SunOS" = ${_SYSTEM} ] ; then
	PS_FLAGS="-ef"
	PS_SUFFIX="sort"
else
	echo "Unknown system ${_SYSTEM}; using defaults..."
fi

export LANG LS_FLAGS LSCOLORS LS_COLORS

_BIN_LS="/bin/ls"
_BIN_PS="/bin/ps"
_BIN_DF="/bin/df"

LS="${_BIN_LS} ${LS_FLAGS}"
export LS

df ()
{
	ARGS="${@}"
	${_BIN_DF} ${DF_FLAGS} ${ARGS}
}

########################################################################
#
# Prompt stuff
#
########################################################################

path () 
{ 
    if test -x /usr/bin/$1; then
        ${1+"/usr/bin/$@"};
    else
        if test -x /bin/$1; then
            ${1+"/bin/$@"};
        fi;
    fi
}

_bred="$(path tput bold 2> /dev/null; path tput setaf 1 2> /dev/null)"
_byel="$(path tput bold 2> /dev/null; path tput setaf 3 2> /dev/null)"
_bgrn="$(path tput bold 2> /dev/null; path tput setaf 2 2> /dev/null)"
_sgr0="$(path tput sgr0 2> /dev/null)"

function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  timer_show=$(($SECONDS - $timer))
  unset timer
}

trap 'timer_start' DEBUG
PROMPT_COMMAND=timer_stop

PS1_TIMER_PREFIX='{${timer_show}s}'

#PS1_PREFIX="(\D{%d %b}, \t) \h"
PS1_PREFIX="$PS1_TIMER_PREFIX \h"

if [ $UID = 0 ] ; then
        PS1="${PS1_PREFIX} [\w] # "
        PS1="\[$_bred\]$PS1\[$_sgr0\]"
elif [ $UID -lt 100 ] ; then
        PS1="${PS1_PREFIX} [\w] > "
        PS1="\[$_byel\]$PS1\[$_sgr0\]"
else
        PS1="${PS1_PREFIX} [\w] $ "
        PS1="\[$_bgrn\]$PS1\[$_sgr0\]"
fi
export PS1

unset _bred _bgrn _sgr0

########################################################################
#
# Common Aliases
#
########################################################################

alias ls="${LS} -C"
alias la="${LS} -aC"
alias lr="${LS} -aCR"

alias dir="${LS} -l"
alias dira="${LS} -al"
alias dirr="${LS} -alR"
alias dirt="${LS} -lrt"
alias dirah="${LS} -alh"
alias dirrah="${LS} -Ralh"
alias diraht="${LS} -alhrt"

alias mv='/bin/mv -i'
alias cp='/bin/cp -i'

alias      j="jobs"
alias  today="date '+%-d %b %Y'"
alias todate="date '+%Y%m%d'"
alias totime="date '+%Y%m%d_%H%M%S'"
alias    now="date '+%Y%m%d_%H%M%S'"

#
# Berkeley Exit Function
#
.()
{
	SCRIPT=$1
	if [ -z $SCRIPT ] ; then
		exit
	else
		source $SCRIPT
	fi
}

#
# h
#
h()
{
        PATTERN=$1
        if [ -z "$PATTERN" ] ; then
                history
        else
                history | grep $PATTERN
        fi
}

#
# kill something process
#
killproc ()
{
	kill `ps ${PS_FLAGS} | grep "${1}" | grep -v grep | awk '{print $2}'`
}

#
# ps
#
p ()
{
	ARGS="${*}"

	if [ -z "$ARGS" ] ; then
		${_BIN_PS} ${PS_FLAGS} | eval ${PS_SUFFIX}
	else
		${_BIN_PS} ${PS_FLAGS} | egrep "$ARGS" | eval ${PS_SUFFIX}
	fi
}

#
# ps | grep -v
#
pv ()
{
	ARGS="${*}"

	if [ -z "$ARGS" ] ; then
		p
	else
		${_BIN_PS} ${PS_FLAGS} | egrep -v "$ARGS" | eval ${PS_SUFFIX}
	fi
}

#
# ps | grep "${USER}"
#
pme ()
{
	p "${USER}"
}

#
# POSIX man behavior
#
export MAN_POSIXLY_CORRECT=1

if [ -d /opt/local/bin ] ; then
	# MacPorts Installer addition: adding an appropriate PATH variable for use with MacPorts.
	export PATH="/opt/local/bin:/opt/local/sbin:$PATH"
	# Finished adapting your PATH environment variable for use with MacPorts.
fi

#
# Personal bin
#
if [ -d $HOME/bin ] ; then
	PATH=$HOME/bin:$PATH
fi

#
# .personal
#
PERSONAL_ALIAS=".alias-$USER"

if [ -e $HOME/.alias-$USER ] ; then
	. $HOME/.alias-$USER
fi

unset PERSONAL_ALIAS


