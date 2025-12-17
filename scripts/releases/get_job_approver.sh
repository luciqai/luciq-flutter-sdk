jobsJson=$(curl -s -X GET "https://circleci.com/api/v2/workflow/$CIRCLE_WORKFLOW_ID/job" --header "Circle-Token: $CIRCLE_TOKEN")

job=$(jq '.items[] | select(.name == "hold_release_luciq_flutter" or .name == "hold_slack_notification") | select(.approved_by != null)' <<< "$jobsJson")

if [ -z "$job" ] || [ "$job" == "null" ]; then
  echo "Error: Could not find approved job in workflow" >&2
  exit 1
fi

approver_id=$(jq '.approved_by' <<< "$job")

approver_id=$(tr -d '"' <<< "$approver_id")

user=$(curl -s -X GET "https://circleci.com/api/v2/user/$approver_id" --header "Circle-Token: $CIRCLE_TOKEN")

username=$(jq '.login' <<< "$user")

username=$(tr -d '"' <<< "$username")

slack_id=$(./scripts/releases/get_slack_id_from_username.sh "$username")

echo "$slack_id"