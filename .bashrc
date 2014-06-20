# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific aliases and functions
if [ -f ~/.bash_aliases ]; then
    . ~/.bash_aliases
fi

export PATH=$HOME/.local/bin:$PATH
export PYTHONPATH=$PYTHONPATH
export LD_LIBRARY_PATH=$HOME/.local/lib64:$HOME/.local/lib:/opt/local/lib64:/opt/local/lib:/usr/local/lib64:/usr/local/lib:$LD_LIBRARY_PATH
export MANPATH=$HOME/.local/share/man:$MANPATH

# !!! NOT proceeding if non-interactive !!! #
if [[ $- != *i* ]]; then
    return
fi

# Activate bash completion script if present
if [ -f /etc/bash_completion ]; then
    . /etc/bash_completion
fi

# PS1 command line customization
PS1='[\u@\h \W$(__git_ps1 " (%s)")]\$ '

# Activate git prompting when requisite file available
if [ -f /usr/share/git-core/contrib/completion/git-prompt.sh ]; then
    . /usr/share/git-core/contrib/completion/git-prompt.sh
    GIT_PS1_SHOWDIRTYSTATE=1
fi

export EDITOR=vim
export LESS="RM"

# Common build extension variables
export LDFLAGS="-L$HOME/.local/lib64 -L$HOME/.local/lib $LDFLAGS"
export C_INCLUDE_PATH=$HOME/.local/include:$C_INCLUDE_PATH
export CPLUS_INCLUDE_PATH=$HOME/.local/include:$CPLUS_INCLUDE_PATH
# cpp as in the c-preprocessor, not c++
export CPPFLAGS="-I$HOME/.local/include $CPPFLAGS"
