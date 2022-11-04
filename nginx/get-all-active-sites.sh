# This line asks nginx for the current config and only returns the hostnames of the active sites.
sudo nginx -T | grep "server_name " | sed 's/.*server_name \(.*\);/\1/' | sed 's/ /\n/' | sed "/\b\(cat\|nginx\)\b/d"
