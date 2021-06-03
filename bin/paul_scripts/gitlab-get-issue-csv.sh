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

ISSUE_JSON="$(\
  curl -sX GET \
  --header "PRIVATE-TOKEN: $(cat "${TOKEN_FILEPATH}")" \
  https://gitlab.kitware.com/api/v4/groups/"${GROUP_ID}"/issues \
  -d per_page=100 \
  -d labels="${ISSUE_TAG}" \
)"

#echo "$ISSUE_JSON"

if [[ "$(echo $ISSUE_JSON | jq '.|length')" -ge 100 ]]
then
  echo "WARNING: Number of issues returned was at the pagination cap." >&2
  echo "         Consider updating this script to handle pagination." >&2
fi

echo "$ISSUE_JSON" \
  | jq -r 'map(select(.closed_by == null))
           | sort_by(.assignee.name, .project_id, .iid)
           | .[]
           | [.references.relative, .title, .web_url, .assignee.name] | @csv'
