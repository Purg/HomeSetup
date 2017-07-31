#
# Helper bash function for setting up a CIFS (samba-share) mount on linux.
#
# Required system packages:
#   cifs-
#

ACCOUNT_NAME="$(whoami)"


#+
# Usage: setup_cifs_mount CREDENTIALS_FILE_PATH \
#                         SERVER_MNT_ADDR \
#                         MOUNT_DIRECTORY_PATH
#
# Mount the given CIFS shared directory to the given system directory using
# the given credentials file.
#
# A credentials file is a simple text file that looks like:
#
#   username=NAME_HERE
#   password=PASSWD_HERE
#
# A server mount address should look something like:
#
#   //argus/data
#     ^     ^
#     |     Served Directory name/path
#     Server Hostname
#
#-
function setup_cifs_mount () {
  credentials_file="$1"
  server="$2"
  dir="$3"

  if [ -z "$(mount | grep "${dir}")" ]
  then
    echo "Attempting mount of ${dir}..."
    sudo mount -t cifs \
      -o "credentials=${credentials_file}" \
      -o uid=${ACCOUNT_NAME} \
      -o gid=${ACCOUNT_NAME} \
      "${server}" \
      "${dir}"
  fi
}
