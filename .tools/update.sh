while IFS=, read -r tag programm comment; do
  echo $tag $programm $comment
  case "$tag" in
    "") sudo pacman --noconfirm --needed -S "$programm" ;;
    "A") sudo -S --noconfirm "$programm" ;;
  esac
done < $HOME/.apps
