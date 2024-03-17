#!/bin/bash

# Variables
MOUNT_PATH="/mnt/share/"
CRED_PATH="$HOME/.smbcredentials"
MOUNTS=("test" "backup" "documents" "fotos" "res" "uni" "projects" "archive" "games")

# Get current user's UID and GID
USR=$(id -u)
GRP=$(id -g)

# Prompt user for SMB server IP address
read -p "Enter the IP address of the SMB server: " SMB_SERVER_IP

# Function to create mount points
create_mount_points() {
    local mount_path="$1"
    local usr="$2"
    local grp="$3"

    if [ ! -d "$mount_path" ]; then
        sudo mkdir -p "$mount_path"
        echo "Created directory: $mount_path"
    fi

    for mount_name in "${MOUNTS[@]}"; do
        local full_path="$mount_path/$mount_name"
        if [ ! -d "$full_path" ]; then
            sudo mkdir -p "$full_path"
            sudo chown "$usr:$grp" "$full_path"
            echo "Created mount point: $full_path"
        else
            echo "Mount point already exists: $full_path"
        fi
    done
}

# Function to create SMB credentials file
create_credentials_file() {
    local cred_path="$1"

    touch "$cred_path"
    read -p "Enter the username for the samba-mount: " smbuser
    read -p "Enter the password for the samba-mount: " smbpw

    echo "username=$smbuser" > "$cred_path"
    echo "password=$smbpw" >> "$cred_path"

    sudo chmod 0600 "$cred_path"
}

# Function to add entries to fstab
add_to_fstab() {
    local mount_path="$1"
    local smb_server_ip="$2"
    local cred_path="$3"
    local usr="$4"
    local grp="$5"

    for mount_name in "${MOUNTS[@]}"; do
        local entry="//${smb_server_ip}/$mount_name $mount_path$mount_name cifs credentials=$cred_path,uid=$usr,gid=$grp 0 0"
        if ! grep -q "$entry" /etc/fstab; then
            echo "$entry" | sudo tee -a /etc/fstab > /dev/null
            echo "Added entry to /etc/fstab: $entry"
        else
            echo "Entry already exists in /etc/fstab: $entry"
        fi
    done
}

main() {
    create_mount_points "$MOUNT_PATH" "$USR" "$GRP"
    create_credentials_file "$CRED_PATH"
    add_to_fstab "$MOUNT_PATH" "$SMB_SERVER_IP" "$CRED_PATH" "$USR" "$GRP"

    # Mount the new volume
    sudo mount -a

    # Refresh systemd daemon
    sudo systemctl daemon-reload

    echo "Mounting completed successfully."
}

main
