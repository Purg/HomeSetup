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
  echo "from a GitLab instace group given by name."
  echo "Assumes a default GitLab instance url if 'https://gitlab.kitware.com'."
  echo "Assumes no default issue tag of (blank string)."
  echo "Assumes default token-file of 'gitlab-api-token.txt'."
  echo
  echo "Options"
  echo "  -h, --help          Show this message."
  echo "  -u, --url           URL of the gitlab API to make use of."
  echo "  -f, --token-file    Path to a file containing access token value."
  echo "  -t, --tag           Non-default tag to get issues for."
  echo "  -i, --iteration     Sub-select issues retrieved based on those in"
  echo "                      the current iteration. This option only makes"
  echo "                      sense in the context of a GitLab instance"
  echo "                      utilizing a tier that has enable iteration"
  echo "                      support."
  echo "  -o, --office        Write the output CSV to a temp file, opening it "
  echo "                      in LibreOffice Calc (removes file after exit)."
  echo
}

GITLAB_URL="https://gitlab.kitware.com"
ISSUE_TAG=""
TOKEN_FILEPATH="${HOME}/gitlab-api-token.txt"

function log {
  >&2 echo "$@"
}

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
    -u|--url)
      GITLAB_URL="$1"
      log "INFO: Using override GitLab REST API URL @ ${GITLAB_URL}"
      shift
      ;;
    -f|--token-file)
      TOKEN_FILEPATH="$1"
      log "INFO: Using override token filepath: ${TOKEN_FILEPATH}"
      shift
      ;;
    -t|--tag)
      ISSUE_TAG="$1"
      log "INFO: Using override issue tag: ${ISSUE_TAG}"
      shift
      ;;
    -i|--iteration)
      FILTER_CURRENT_ITERATION=yes
      log "INFO: Considering only current iteration issues."
      ;;
    -o|--office)
      OPEN_IN_OFFICE=yes
      log "INFO: Opening resulting CSV into OpenOffice"
      ;;
    *)
      POSITIONAL+=("$key")
      ;;
  esac
done

if [[ ! -f "${TOKEN_FILEPATH}" ]]
then
  log "ERROR: No file at the given path to use for a token!"
  log "       Currently: ${TOKEN_FILEPATH}"
  exit 1
fi

if [[ "${#POSITIONAL[@]}" -gt 1 ]]
then
  log "ERROR: Expected only one positional argument!"
  log "       Instead received: " "${POSITIONAL[@]}"
  exit 1
fi

log "INFO: Acquiring groups list from ${GITLAB_URL}"
GROUP_NAME="${POSITIONAL[0]}"
GROUP_JSON=$(\
  curl -sX GET --header "PRIVATE-TOKEN: $(cat "${TOKEN_FILEPATH}")" \
  "${GITLAB_URL}"/api/v4/groups
)
# Attempt to isolate the specific ID of the currently input group name.
log "INFO: Checking for presence of '${GROUP_NAME}' in the list."
GROUP_ID=$(\
  echo "$GROUP_JSON" \
  | jq -r ".[] | select(.name == \"${GROUP_NAME}\") | .id" \
)
if [[ -z "$GROUP_ID" ]]
then
  # Extract the list of quoted names.
  GROUP_NAMES="$(echo "$GROUP_JSON" | jq ".[] | .name")"
  log "ERROR: Could not find a group with the given name '$GROUP_NAME'"
  log "       Available group names are:"
  log "${GROUP_NAMES}"
  exit 1
fi
log "INFO: Group \"${GROUP_NAME}\" ID: ${GROUP_ID}"

if [[ "${FILTER_CURRENT_ITERATION}" = "yes" ]]
then
  log "INFO: Filtering by the current iteration: figuring out which that is."
  CUR_ITER_JSON=$( \
    curl -sX GET --header "PRIVATE-TOKEN: $(cat "${TOKEN_FILEPATH}")" \
    "${GITLAB_URL}"/api/v4/groups/"${GROUP_ID}"/iterations \
    -d state=current
  )
  if [[ "$(echo "$CUR_ITER_JSON" | jq length)" -ne 1 ]]
  then
    # More than one iteration returned as the current?
    log "ERROR: More than one iteration is apparently \"current\"."
    exit 1
  fi
  CUR_ITER_ID="$(echo "$CUR_ITER_JSON" | jq ".[].id")"
  log "INFO: Current iteration ID: ${CUR_ITER_ID}"
  CUR_ITER_ARGS=( -d iteration_id="${CUR_ITER_ID}" )
fi

log "INFO: Acquiring issue JSON"
ISSUE_JSON="$(\
  curl -sX GET \
  --header "PRIVATE-TOKEN: $(cat "${TOKEN_FILEPATH}")" \
  "${GITLAB_URL}"/api/v4/groups/"${GROUP_ID}"/issues \
  -d per_page=100 \
  -d labels="${ISSUE_TAG}" \
  -d state=opened \
  "${CUR_ITER_ARGS[@]}" \
)"

#echo "$ISSUE_JSON"
#exit 0

if [[ "$(echo $ISSUE_JSON | jq '.|length')" -ge 100 ]]
then
  log "WARNING: Number of issues returned was at the pagination cap." >&2
  log "         Consider updating this script to handle pagination." >&2
fi

function do_items_query()
{
  echo "$ISSUE_JSON" \
    | jq -r "sort_by(.assignee.name, .project_id, .iid)
             | .[]
             | [.references.relative, .title, .web_url, .assignee.name]
             | @csv"
}

function do_items_query_spreadsheet()
{
  echo "$ISSUE_JSON" \
    | jq -r "sort_by(.assignee.name, .project_id, .iid)
             | .[]
             | [.title, \"=HYPERLINK(\\\"\" + .web_url + \"\\\", \\\"\" + .references.relative + \"\\\")\", .assignee.name]
             | @csv"
}

if [[ "$OPEN_IN_OFFICE" != "yes" ]]
then
  log "INFO: Outputting to STDOUT"
  do_items_query
else
  TMP_OUTPUT="$(mktemp --suffix=.csv)"
  log "INFO: Creating temp file: ${TMP_OUTPUT}"
  do_items_query_spreadsheet >"${TMP_OUTPUT}"
  log "INFO: Opening in LibreOffice"
  libreoffice "$TMP_OUTPUT"
  log "INFO: Removing temp file: ${TMP_OUTPUT}"
  rm "$TMP_OUTPUT"
fi
