#!/bin/bash
print_help() {
  cat >&2 <<EOF
Syntax: $0 [OPTION]...

  -b, --backup-dir=PATH   use PATH as backup directory instead of generating one
  -h, --help              print this help
  -c, --config-only       only install config files, no programs
  -d, --dry-run		  just print echos
  -e, --desktop-env	  install stuff that need desktop-env too
  -g, --global-install	  install stuff with sudo
EOF
  exit 0
}

add_gnome_shortcut() {
    local name="$1"
    local command="$2"
    local binding="$3"
    local use_terminal="${4:-false}"  # Par défaut, `false` si non spécifié

    if [[ -z "$name" || -z "$command" || -z "$binding" ]]; then
        echo "🛑 Usage: add_gnome_shortcut <nom> <commande> <raccourci> [true/false]"
        return 1
    fi


    if [[ "$use_terminal" == "true" ]]; then
    	local terminal_cmd=""
        if command -v alacritty &>/dev/null; then
            terminal_cmd="alacritty -e bash -c '$command'"
        elif command -v gnome-terminal &>/dev/null; then
            terminal_cmd="gnome-terminal -- bash -c '$command'"
        else
            echo "🛑 Aucun terminal compatible trouvé (Alacritty ou GNOME Terminal)."
            return 1
        fi
        command="$terminal_cmd"
    fi

    local current_keys
    current_keys=$(gsettings get org.gnome.settings-daemon.plugins.media-keys custom-keybindings | tr -d "[]',")
    if [[ "$current_keys" == "@as " ]]; then
	    current_keys=""
    fi

    local conflict_key=""

    # Vérifier si un raccourci existe déjà avec le même binding, nom ou commande
    for key in $current_keys; do
        existing_name=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key name 2>/dev/null | tr -d "'")
        existing_command=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key command 2>/dev/null | tr -d "'")
        existing_binding=$(gsettings get org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key binding 2>/dev/null | tr -d "'")

        if [[ "$existing_name" == "$name" && "$existing_command" == "$command" && "$existing_binding" == "$binding" ]]; then
	    echo "✅ Existe déjà tel quel !"
            echo "   🔹 OLD => $existing_name, $existing_command, $existing_binding"
            echo "   🔹 NEW => $name, $command, $binding"
	    return 0
        elif [[ "$existing_name" == "$name" || "$existing_command" == "$command" || "$existing_binding" == "$binding" ]]; then
            echo "🛑 Conflit détecté avec un raccourci existant :"
            echo "   🔹 OLD => $existing_name, $existing_command, $existing_binding"
            echo "   🔹 NEW => $name, $command, $binding"
            echo -n "❓ Voulez-vous le remplacer ? [Y/n] "
            read -r response
            if [[ "$response" =~ ^(y|Y|yes|YES)?$ ]]; then
                echo "🗑️  Suppression du raccourci '$existing_name'..."
                gsettings reset-recursively org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$key
                conflict_key="$key"
                break
            else
                echo "Annulation de l'ajout du raccourci."
                return 0
            fi
	fi
    done

    # Si un conflit a été trouvé, utiliser `conflict_key`, sinon trouver un nouvel index libre
    local path
    if [[ -n "$conflict_key" ]]; then
        path="$conflict_key"
    else
        local index=0
        while [[ $current_keys == *"custom${index}"* ]]; do
            ((index++))
        done
        path="/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom${index}/"
	
	local new_list
        if [[ -z "$current_keys" ]]; then
            new_list="['$path']"
        else
	    new_list="[$(printf "'%s', " $current_keys)'$path']"
        fi
        gsettings set org.gnome.settings-daemon.plugins.media-keys custom-keybindings "$new_list"

    fi

    # Ajouter ou remplacer le raccourci
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path name "$name"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path command "$command"
    gsettings set org.gnome.settings-daemon.plugins.media-keys.custom-keybinding:$path binding "$binding"

    echo "✅ Raccourci ajouté : $name ($binding → $command) avec $( [[ "$use_terminal" == "true" ]] && echo "terminal" || echo "exécution directe" )"
}


install_config() {
  local path_dest="$HOME/$2"
  local create_link='false'

  if [[ -e "$path_dest" ]] ; then
    if [[ -z "$(find "$path_dest" -type l)" ]] ; then
      mkdir -p "$(dirname "$BACKUP_DIR/$2")"
      mv "$path_dest" "$BACKUP_DIR/$2"
      create_link='true'
    fi
  else
    dest_dir=$(dirname $path_dest)
    if [[ ! -e "$dest_dir" ]] ; then
      mkdir -p "$dest_dir"
    fi

    create_link='true'
  fi

  if [[ "$create_link" = 'true' ]] ; then
    echo -n "  "
    ln -vfsr "$1" "$path_dest"  
  fi
}

generate_backup_dir() {
  local backup_dir_model='/tmp/backup_home_XXXXXX'
  BACKUP_DIR="$(mktemp -d "$backup_dir_model")"
  echo "backup dir: $BACKUP_DIR"
}

options=$(getopt -o hb:cdge -l help,backup-dir:,config-only,desktop-env,global-install,dry-run  -n "$0" -- "$@")
eval set -- "$options"

ARGS=("$@")
BACKUP_DIR=
CONFIG_ONLY=
ENABLE_DE=
GLOBAL_INSTALL=
DRY_RUN=

while true ; do
  case "$1" in
    -h | --help ) print_help ;;
    -b | --backup-dir ) BACKUP_DIR=$2 ; shift 2 ;;
    -c | --config-only ) CONFIG_ONLY=1 ; shift ;;
    -e | --desktop-env ) ENABLE_DE=1 ; shift ;;
    -g | --global-install ) GLOBAL_INSTALL=1; shift ;;
    -d | --dry-run ) DRY_RUN=1; shift ;;
    -- ) shift ; break ;;
    * ) echo >&2 "Error: Unknown option '$1'." ; exit 1 ;;
  esac
done

if [[ ! "$BACKUP_DIR" ]] ; then
  generate_backup_dir
fi

DE=
shopt -s nocasematch
if [[ "ENABLE_DE" ]] ; then
	case "$XDG_CURRENT_DESKTOP" in
		*gnome* ) DE=gnome ;;
		* ) DE=unknown ;;
	esac
fi
shopt -u nocasematch
