acl_fix() {
  local user=$(whoami)
  
  if [ $# -eq 0 ]; then
    echo "Usage: acl_fix <directory> [directory...]"
    return 1
  fi
  
  for dir in "$@"; do
    if [ ! -d "$dir" ]; then
      echo "Error: '$dir' is not a directory"
      continue
    fi
    
    echo "Setting ACLs on $dir for user $user..."
    sudo setfacl -R -m u:$user:rwX "$dir"
    sudo setfacl -R -m m::rwX "$dir"
    sudo setfacl -R -d -m u:$user:rwX "$dir"
    sudo setfacl -R -d -m m::rwX "$dir"
    echo "Done: $dir"
  done
}

tsesh() {
  if [ $# -ne 1 ]; then
    echo "Usage: tsesh <name>"
    return 1
  fi

  tmux new -ADs "$1"
}
