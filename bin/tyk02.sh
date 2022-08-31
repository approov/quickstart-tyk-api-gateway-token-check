#!/bin/sh

set -eu

Show_Help() {
  cat <<EOF

  A bash script wrapper for Docker Compose and for the Tyk API Gateway.


  SYNOPSIS:

  $ ./tyk <command> <argument>


  COMMANDS:

  api-setup               Creates and configures a new API
                          ./tyk api-setup

  api-request             Sends one-off API request to /uuid endpoint
                          ./tyk api-request

  get-api                 Gets the API configuration for an API ID
                          ./tyk get-api
                          ./tyk get-api httpbin

  get-apis                Gets all APIs configurations
                          ./tyk get-apis



  create-security-policy

EOF
}

Get_Api() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/apis/${API_ID} \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool #> .local/api.json

  echo
}

Get_Apis() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/apis \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool

  echo
}

Create_Api() {
  curl http://"${TYK_HOST}":"${TYK_PORT}"/tyk/apis \
    -i \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{
      \"api_id\": \"${API_ID}\",
      \"slug\": \"${API_SLUG}\",
      \"name\": \"${API_NAME}\",
      \"org_id\": \"1\",
      \"auth\": {
        \"auth_header_name\": \"${AUTH_HEADER_NAME}\"
      },
      \"definition\": {
        \"location\": \"header\",
        \"key\": \"x-api-version\"
      },
      \"version_data\": {
        \"not_versioned\": true,
        \"versions\": {
          \"Default\": {
            \"name\": \"Default\",
            \"use_extended_paths\": true
          }
        }
      },
      \"proxy\": {
        \"listen_path\": \"${PROXY_LISTEN_PATH}\",
        \"target_url\": \"${PROXY_TARGET_URL}\",
        \"strip_listen_path\": ${PROXY_STRIP_LISTEN_PATH}
      },
      \"active\": true,
      \"enable_jwt\": true,
      \"jwt_signing_method\": \"hmac\",
      \"jwt_identity_base_field\": \"iss\",
      \"jwt_default_policies\": [
        \"${SECURITY_POLICY_ID}\"
      ],
      \"jwt_source\": \"${APPROOV_BASE64_SECRET}\"

    }"  # | python -mjson.tool

    echo
}

Get_Api_Key() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/keys/${1:? Missing the API key to retrieve.} \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool #> .local/api.json

  echo
}

Get_Api_Keys() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/keys \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool

  echo
}

Create_Api_Key() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/keys/create \
    -i \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{
      \"allowance\": 1000,
      \"rate\": 1000,
      \"per\": 1,
      \"expires\": -1,
      \"quota_max\": -1,
      \"org_id\": \"1\",
      \"quota_renews\": 1449051461,
      \"quota_remaining\": -1,
      \"quota_renewal_rate\": 60,
      \"access_rights\": {
        \"${API_ID}\": {
          \"api_id\": \"${API_ID}\",
          \"api_name\": \"${API_NAME}\",
          \"versions\": [\"Default\"]
        }
      },
      \"meta_data\": {},
      \"apply_policy_id\": \"${SECURITY_POLICY_ID}\"

    }" # | python -mjson.tool

    echo
}

Get_Security_Policy() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/policies/${SECURITY_POLICY_ID} \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool

  echo
}

Get_Security_Policies() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/policies \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool

  echo
}

Create_Security_Policy() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/policies \
    -i \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "
      {
        \"id\": \"${SECURITY_POLICY_ID}\",
        \"access_rights\": {
          \"${API_ID}\": {
            \"allowed_urls\": [],
            \"api_id\": \"${API_ID}\",
            \"api_name\": \"${API_NAME}\",
            \"versions\": [
                \"Default\"
            ]
          }
        },
        \"org_id\": \"1\",
        \"active\": true,
        \"name\": \"${SECURITY_POLICY_NAME}\",
        \"rate\": 0,
        \"per\": 1,
        \"quota_max\": -1,
        \"state\": \"active\",
        \"tags\": [\"Approov\"]
      }"

  echo
}

Reload() {
  curl -i -H "x-tyk-authorization: ${TYK_GW_SECRET}" -s http://${TYK_HOST}:${TYK_PORT}/tyk/reload/group
  echo
}

Send_Api_Request() {
  local _api_slug="${1:? Missing the API slug, eg. uuid}"

  curl http://${TYK_HOST}:${TYK_PORT}/${_api_slug} \
      -i \
      -H "Approov-Token: ${2? Missing Approov token.}" \
      -H "Content-Type: application/json"

  echo
}

Test_Approov_Token_Valid() {
  echo "\n---> Valid Approov Token\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.u-rlLdZgaYUjUpU_wWi7nzeMgae_IfcT7asu22ptXn0'

  echo
}

Test_Approov_Token_Expired() {
  echo "\n---> Expired Approov Token\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjE2NjE1MzAxMjB9.bdl_U893ahMEV5bEp7mPAIkRr53qVA0iuZs0LqvSIho'

  echo
}

Test_Approov_Token_Invalid_Signature() {
  echo "\n---> Invalid Signature for the Approov Token\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.u-rlLdZgaYUjUpU_wWi7nasMgae_IfcT7asu22ptXn0'

  echo
}

Test_Approov_Token_Missing() {
  echo "\n---> The Approov Token is missing in the request headers\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json'

  echo
}

Test_Approov_Token_Empty() {
  echo "\n---> The Approov Token in the request headers is empty\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H 'Approov-Token: '

  echo
}


Test_Approov() {
  for input in "${@:-}"; do
    case "${input}" in
      valid )
        Test_Approov_Token_Valid
      ;;

      invalid-signature )
        Test_Approov_Token_Invalid_Signature
      ;;

      expired )
        Test_Approov_Token_Expired
      ;;

      missing )
        Test_Approov_Token_Missing
      ;;

      empty )
        Test_Approov_Token_Empty
      ;;

      * )
        Test_Approov_Token_Valid
        Test_Approov_Token_Invalid_Signature
        Test_Approov_Token_Expired
        Test_Approov_Token_Missing
        Test_Approov_Token_Empty
      ;;
    esac
  done
}

Main() {

  local TYK_HOST=localhost
  local TYK_PORT=8002

  local PROXY_LISTEN_PATH=/
  local PROXY_TARGET_DOMAIN=httpbin.org
  local PROXY_TARGET_URL=https://${PROXY_TARGET_DOMAIN}
  local PROXY_STRIP_LISTEN_PATH=true

  local API_ID=${PROXY_TARGET_DOMAIN}
  local API_NAME=HttpBin
  local API_SLUG=httpbin

  local AUTH_HEADER_NAME=Approov-Token

  local SECURITY_POLICY_ID=approov
  local SECURITY_POLICY_NAME=Approov

  . ./.env

  for input in "${@}"; do
    case "${input}" in
      -h | --help )
        sudo docker-compose --help
        echo "\n\n-----------------------------------------------------------------------\n"
        Show_Help
        exit $?
      ;;

      api-setup )
        Create_Api
        Create_Security_Policy
        # Create_Api_Key
        Reload
      ;;

      api-request )
        shift 1
        Send_Api_Request "${@}"
        exit $?
      ;;

      get-api )
        API_ID=${2:-$API_ID}
        Get_Api
        exit $?
      ;;

      get-apis )
        Get_Apis
        exit $?
      ;;

      create-api )
        Create_Api
        exit $?
      ;;

      get-api-key )
        shift 1
        Get_Api_Key "${@}"
        exit $?
      ;;

      get-api-keys )
        Get_Api_Keys
        exit $?
      ;;

      create-api-key )
        Create_Api_Key
        exit $?
      ;;

      get-security-policy )
        SECURITY_POLICY_ID=${2:-$SECURITY_POLICY_ID}
        Get_Security_Policy
        exit $?
      ;;

      get-security-policies )
        Get_Security_Policies
        exit $?
      ;;

      create-security-policy )
        Create_Security_Policy
        exit $?
      ;;

      reload )
        Reload
        exit $?
      ;;

      test-approov-token )
        shift 1
        Test_Approov "${@}"
        exit $?
      ;;

      * )
        sudo docker-compose ${@}
        exit $?
      ;;
    esac
  done

  Show_Help
}

Main "${@}"
