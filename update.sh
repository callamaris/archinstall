while IFS=, read -r tag programm comment; do
  echo $tag $programm $comment
done < $HOME/.apps
