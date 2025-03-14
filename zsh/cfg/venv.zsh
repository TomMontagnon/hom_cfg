update_venv() {
  venv_dirname='.venv'

  # automatically deactivate when leaving a (sub-)directory containing a virtual env
  if [[ -v VIRTUAL_ENV && ${PWD:P}/ != ${VIRTUAL_ENV:P:h}/* ]] ; then
    deactivate
  fi

  if [[ -d "${venv_dirname}" ]] ; then
    source "${venv_dirname}/bin/activate"
  fi
}

autoload -U add-zsh-hook
add-zsh-hook chpwd update_venv

# call it when a new terminal is open
update_venv
