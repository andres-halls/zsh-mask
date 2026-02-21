HISTORY_EXCLUDE_PATTERN='^ |//([^/]+:[^/]+)@|KEY[=:] *([^ ]+)|TOKEN[=:] *([^ ]+)|BEARER[=:] *([^ ]+)|PASSWO?R?D?[=:] *([^ ]+)|Authorization[=:] *([^'"'"'\"]+)|-us?e?r? ([^:]+:[^:]+) '

typeset -a _zshaddhistory_functions

# See
# - https://zsh.sourceforge.io/Doc/Release/Functions.html for docs on zshaddhistory
# - https://zsh.sourceforge.io/Doc/Release/Shell-Builtin-Commands.html for docs on print
function zshaddhistory() {
  emulate -L zsh
  unsetopt case_match

  if [[ -z "$orig_histfile" ]]; then
    orig_histfile="$HISTFILE"
  fi

  if [[ ${#_zshaddhistory_functions[@]} -eq 0 ]] && [[ ${#zshaddhistory_functions[@]} -gt 0 ]]; then
    _zshaddhistory_functions=("${zshaddhistory_functions[@]}")
  elif [[ ${#_zshaddhistory_functions[@]} -gt 0 ]]; then
    zshaddhistory_functions=("${_zshaddhistory_functions[@]}")
  fi

  # respect hist_ignore_space
  if [[ -o hist_ignore_space ]] && [[ "$1" == \ * ]]; then
    return 1
  fi

  local input="${1%%$'\n'}"
  if ! [[ "$input" =~ "$HISTORY_EXCLUDE_PATTERN" ]]; then
    return 0
  fi

  print -Sr -- "$input"
  fc -p "$orig_histfile"

  nonempty=($match)
  if [[ $#nonempty -gt 0 ]]; then
    for m in "$nonempty[@]"; do
      n="${m##[\"\']}"
      input="${input//${n%%[\"\']}/...}"
    done

    print -Sr -- "$input"
  fi
  unset match

  # instantly write history if set options require it.
  if [[ -o share_history ]] || \
    [[ -o inc_append_history ]] || \
    [[ -o inc_append_history_time ]]; then
  fc -AI "$HISTFILE"
  fi

  # prevent other hooks from running
  zshaddhistory_functions=()
  return 1
}
