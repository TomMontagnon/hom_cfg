cfg_fzf_dir='/opt/fzf'
if [[ ! -d "${cfg_fzf_dir}" ]] ; then
  cfg_fzf_dir="${HOME}/share/fzf"
fi

if [[ -d "${cfg_fzf_dir}" ]] ; then
  source "${cfg_fzf_dir}/shell/completion.zsh"
  source "${cfg_fzf_dir}/shell/key-bindings.zsh"

  _fzf_compgen_path() {
    fd --hidden --follow --exclude ".git" . "$1"
  }

  # Use fd to generate the list for directory completion
  _fzf_compgen_dir() {
    fd --type d --hidden --follow --exclude ".git" . "$1"
  }

fi

unset cfg_fzf_dir
