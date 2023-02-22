#!/bin/bash
#
# Requires
# * curl
# * jq
#

function usage {
  echo "Usage: ${BASH_SOURCE[0]} [OPTIONS] GROUP_NAME"
  echo
  echo "Get issues for a tag and output CSV for an agile poker table."
  echo "from a gitlab.kitware.com group given by name."
  echo "Assumes a default issue tag of 'Sprint - Backlog'."
  echo "Assumes default token-file of 'gitlab-api-token.txt'."
  echo
  echo "Options"
  echo "  -h, --help          Show this message."
  echo "  -f, --token-file    Path to a file containing access token value."
  echo "  -t, --tag           Non-default tag to get issues for."
  echo "  -o, --office        Write the output CSV to a temp file, opening it "
  echo "                      in LibreOffice Calc (removes file after exit)."
  echo
}

ISSUE_TAG="Sprint - Backlog"
TOKEN_FILEPATH="${HOME}/gitlab-api-token.txt"

POSITIONAL=()
while [[ "$#" -gt 0 ]]
do
  key="$1"
  shift

  case $key in
    -h|--help)
      usage
      exit 0
      ;;
    -f|--token-file)
      TOKEN_FILEPATH="$1"
      shift
      ;;
    -t|--tag)
      ISSUE_TAG="$1"
      shift
      ;;
    -o|--office)
      OPEN_IN_OFFICE=yes
      ;;
    *)
      POSITIONAL+=("$key")
      ;;
  esac
done

if [[ ! -f "${TOKEN_FILEPATH}" ]]
then
  echo "ERROR: No file at the given path to use for a token!"
  echo "       Currently: ${TOKEN_FILEPATH}"
  exit 1
fi

if [[ "${#POSITIONAL[@]}" -gt 1 ]]
then
  echo "ERROR: Expected only one positional argument!"
  echo "       Instead received: ${POSITIONAL[@]}"
  exit 1
fi

GROUP_NAME="${POSITIONAL[0]}"
GROUP_ID=$(\
  curl -sX GET --header "PRIVATE-TOKEN: $(cat "${TOKEN_FILEPATH}")" \
  https://gitlab.kitware.com/api/v4/groups \
  | jq -r ".[] | select(.name == \"${GROUP_NAME}\") | .id" \
)
if [[ -z "$GROUP_ID" ]]
then
  echo "ERROR: Could not find a group with the given name '$GROUP_NAME'"
  exit 1
fi
echo "Group \"${GROUP_NAME}\" ID: ${GROUP_ID}" >&2

ISSUE_JSON="$(\
  curl -sX GET \
  --header "PRIVATE-TOKEN: $(cat "${TOKEN_FILEPATH}")" \
  https://gitlab.kitware.com/api/v4/groups/"${GROUP_ID}"/issues \
  -d per_page=100 \
  -d labels="${ISSUE_TAG}" \
  -d state=opened \
)"

#echo "$ISSUE_JSON"

if [[ "$(echo $ISSUE_JSON | jq '.|length')" -ge 100 ]]
then
  echo "WARNING: Number of issues returned was at the pagination cap." >&2
  echo "         Consider updating this script to handle pagination." >&2
fi

function do_items_query()
{
echo "$ISSUE_JSON" \
  | jq -r 'sort_by(.assignee.name, .project_id, .iid)
           | .[]
           | [.references.relative, .title, .web_url, .assignee.name] | @csv'
}

if [[ "$OPEN_IN_OFFICE" != "yes" ]]
then
  do_items_query
else
  TMP_OUTPUT="$(mktemp --suffix=.csv)"
  echo "INFO: Creating temp file: ${TMP_OUTPUT}"
  do_items_query >"${TMP_OUTPUT}"
  echo "INFO: Opening in LibreOffice"
  libreoffice "$TMP_OUTPUT"
  echo "INFO: Removing temp file: ${TMP_OUTPUT}"
  rm "$TMP_OUTPUT"
fi
