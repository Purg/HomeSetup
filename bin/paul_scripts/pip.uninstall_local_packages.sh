#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_DIR="${HOME}/.local"
echo pip uninstall -y $(ls "${LOCAL_DIR}/lib/python3.8/site-packages/" | grep -Po "(.*)(?=-\d+)")
