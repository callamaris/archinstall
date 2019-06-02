while IFS=, read -r tag programm comment; do
  echo $tag $programm $comment
  case "$tag" in
    "") pacman --noconfirm --needed -S "$programm"
    "A") sudo -u $USER -S --noconfirm "$programm"
  esac
done < $HOME/.apps
