while IFS=, read -r tag programm comment; do
  echo $tag $programm $comment
  case "$tag" in
    "") sudo -u $(whoami) pacman --noconfirm --needed -S "$programm" ;;
    "A") sudo -u $(whoami) -S --noconfirm "$programm" ;;
  esac
done < $HOME/.apps
