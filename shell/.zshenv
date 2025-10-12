# Preferred editor for local and remote sessions
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
else
  export EDITOR='nvim'
fi

# export PATH="$(npm bin -g):$PATH"
export PATH="$HOME/.local/bin:$PATH"
export NOTES_DIR="$HOME/notes"

### FLUTTER DEV ###
# flutter SDK path (phone app development)
export PATH="$HOME/dev/flutter/bin:$PATH"
# Ruby path
export PATH="/opt/homebrew/opt/ruby/bin:$PATH"
# Add cocoapods lib path
export PATH="/opt/homebrew/lib/ruby/gems/3.4.0/bin:$PATH"
# Android
export ANDROID_HOME=$HOME/Library/Android/sdk
export PATH=$ANDROID_HOME/cmdline-tools/latest/bin:$ANDROID_HOME/platform-tools:$PATH
