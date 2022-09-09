#!/bin/sh

set -eu

Show_Help() {
  cat <<EOF

  A bash script wrapper for Docker Compose and for the Tyk API Gateway.


  SYNOPSIS:

  ./tyk <command> [sub-command] [argument]


  COMMANDS:

  setup jwt-api                       Creates an API configuration:
                                      ./tyk setup jwt-api

  setup jwt-security-policy           Creates the security policy for Approov:
                                      ./tyk setup jwt-security-policy

  setup python-build-bundle           Builds the Approov Python plugin bundle:
                                      ./tyk setup python-build-bundle

  setup python-plugin-api             Creates the API configuration:
                                      ./tyk setup python-plugin-api

  setup python-plugin-api-key         Creates the API key configuration:
                                      ./tyk setup python-plugin-api-key

  setup python-plugin-security-policy Creates the security policy for Approov:
                                      ./tyk setup python-plugin-security-policy

  inspect get-api                     Gets the API configuration for an API ID:
                                      ./tyk inspect get-api
                                      ./tyk inspect get-api httpbin

  inspect get-apis                    Gets all APIs configurations:
                                      ./tyk inspect get-apis

  inspect get-security-policy         Get a security policy by ID:
                                      ./tyk inspect get-security-policy
                                      ./tyk inspect get-security-policy approov

  inspect get-security-policies       Get all security policies:
                                      ./tyk inspect get-security-policies

  test send-api-request               Sends one-off API request to /uuid endpoint:
                                      ./tyk test send-api-request <approov-token-here>

  test approov-token                  Comphreensive set of tests for the Approov token:
                                      ./tyk test approov-token
                                      ./tyk test approov-token valid
                                      ./tyk test approov-token invalid-signature
                                      ./tyk test approov-token expired
                                      ./tyk test approov-token missing
                                      ./tyk test approov-token empty

  stack up                            Brings up the docker stack for Tyk and Redis:
                                      ./tyk stack up
                                      ./tyk stack up --detach

  stack reload                        Reloads the Tyk API Gateway:
                                      ./tyk stack reload

  stack down                          Brings donw the docker stack for Tyk and Redis:
                                      ./tyk stack down

  stack logs                          Tails the docker stack logs:
                                      ./tyk stack logs --follow
                                      ./tyk stack logs --follow tyk-gateway
                                      ./tyk stack logs --follow tyk-redis

  stack shell                         Get a shell inside the running Tyk Gateway:
                                      ./tyk stack shell

EOF
}


################
# Tyk Inspect
################

Tyk_Inspect() {
  for input in "${@:-}"; do
    case "${input}" in
      get-api )
        shift 1
        API_ID=${1:-$API_ID}
        Tyk_Inspect_Get_Api
        exit $?
      ;;

      get-apis )
        shift 1
        Tyk_Inspect_Get_Apis
        exit $?
      ;;

      get-security-policy )
        shift 1
        SECURITY_POLICY_ID=${1:-$SECURITY_POLICY_ID}
        Tyk_Inspect_Get_Security_Policy
        exit $?
      ;;

      get-security-policies )
        shift 1
        Tyk_Inspect_Get_Security_Policies
        exit $?
      ;;
    esac
  done
}

Tyk_Inspect_Get_Api() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/apis/${API_ID} \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool #> .local/api.json

  echo
}

Tyk_Inspect_Get_Apis() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/apis \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool

  echo
}

Tyk_Inspect_Get_Security_Policy() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/policies/${SECURITY_POLICY_ID} \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool

  echo
}

Tyk_Inspect_Get_Security_Policies() {
  curl http://${TYK_HOST}:${TYK_PORT}/tyk/policies \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" | python -mjson.tool

  echo
}


############################
# Tyk Setup
############################

Tyk_Setup() {
  for input in "${@:-}"; do
    case "${input}" in
      jwt-api )
        shift 1
        Tyk_Setup_Jwt_Api
        exit $?
      ;;

      jwt-security-policy )
        shift 1
        Tyk_Setup_Jwt_Security_Policy
        exit $?
      ;;

      python-build-bundle )
        shift 1
        Tyk_Setup_Python_Plugin_Build_Bundle
        exit $?
      ;;

      python-plugin-api )
        shift 1
        Tyk_Setup_Python_Plugin_Api
        exit $?
      ;;

      python-plugin-api-key )
        shift 1
        Tyk_Setup_Python_Plugin_Api_Key
        exit $?
      ;;

      python-plugin-security-policy )
        shift 1
        Tyk_Setup_Python_Plugin_Security_Policy
        exit $?
      ;;

    esac
  done
}

Tyk_Setup_Jwt_Api() {
  echo "\n---> Tyk Setup JWT: Creating the API..."

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

Tyk_Setup_Jwt_Security_Policy() {
  echo "\n---> Tyk Setup JWT: Creating the Security Policy..."

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

Tyk_Setup_Python_Plugin_Build_Bundle() {
  echo "\n---> Tyk Setup Python Plugin: Creating the bundle..."

  # If we don't remove the old bundle the new one will not be loaded, unless we
  # give it a another name, that also requires to change the API definition.
  sudo rm -rf ./middleware/bundles/*
  sudo docker-compose run --rm tyk-build-bundle
}

Tyk_Setup_Python_Plugin_Security_Policy() {
  echo "\n---> Tyk Setup Python Plugin: Creating the Security Policy..."

  curl http://${TYK_HOST}:${TYK_PORT}/tyk/policies \
    -i \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "
      {
        \"id\": \"${SECURITY_POLICY_ID}.python\",
        \"access_rights\": {
          \"${API_ID}.python\": {
            \"allowed_urls\": [],
            \"api_id\": \"${API_ID}.python\",
            \"api_name\": \"${API_NAME} Python Plugin\",
            \"versions\": [
                \"Default\"
            ]
          }
        },
        \"org_id\": \"1\",
        \"active\": true,
        \"name\": \"${SECURITY_POLICY_NAME} Python Plugin\",
        \"rate\": 0,
        \"per\": 1,
        \"quota_max\": -1,
        \"state\": \"active\",
        \"tags\": [\"Approov\"]
      }"

  echo
}

Tyk_Setup_Python_Plugin_Api() {
  echo "\n---> Tyk Setup Python Plugin: Creating the API..."

  curl http://"${TYK_HOST}":"${TYK_PORT}"/tyk/apis \
    -i \
    -s \
    -H "x-tyk-authorization: ${TYK_GW_SECRET}" \
    -H "Content-Type: application/json" \
    -X POST \
    -d "{
      \"api_id\": \"${API_ID}.python\",
      \"slug\": \"${API_SLUG}\",
      \"name\": \"${API_NAME} Python Plugin\",
      \"org_id\": \"1\",
      \"auth\": {
        \"auth_header_name\": \"Api-Key\"
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
      \"enable_jwt\": false,
      \"use_keyless\": false,
      \"custom_middleware_bundle\": \"bundle.zip\"
    }"  # | python -mjson.tool

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
        \"${API_ID}.python\": {
          \"api_id\": \"${API_ID}.python\",
          \"api_name\": \"${API_NAME} Python Plugin\",
          \"versions\": [\"Default\"]
        }
      },
      \"meta_data\": {},
      \"apply_policy_id\": \"${SECURITY_POLICY_ID}.python\"
    }" # | python -mjson.tool
}


Tyk_Setup_Python_Plugin_Api_Key() {
  echo "\n---> Tyk Setup Python Plugin: Creating the API key..."

  local _response="$(Create_Api_Key)"
  local _api_key="$(echo "${_response}" | grep -o '"key":"[^"]*' | grep -o '[^"]*$')"

  if grep -q "^API_KEY=" "./.env"; then
    sed -i -e "s|^API_KEY=.*|API_KEY=${_api_key}|" "./.env"
  else
    echo "API_KEY=${_api_key}" >> "./.env"
  fi

  echo "${_response}"
}


############################
# Tyk Test
############################

Tyk_Test() {
  for input in "${@:-}"; do
    case "${input}" in
      send-api-request )
        shift 1
        Tyk_Test_Send_Api_Request "${@}"
        exit $?
      ;;

      approov-token )
        shift 1
        Tyk_Test_Approov "${@}"
        exit $?
      ;;

      * )
        Show_Help
        exit $?
      ;;
    esac
  done
}

Tyk_Test_Send_Api_Request() {
  local _api_slug="${1:? Missing the API slug, eg. uuid}"

  curl http://${TYK_HOST}:${TYK_PORT}/${_api_slug} \
      -i \
      -H "Approov-Token: ${2? Missing Approov token.}" \
      -H "Api-Key: ${3:-${API_KEY}}" \
      -H "Content-Type: application/json"

  echo
}

Tyk_Test_Approov() {
  for input in "${@:-}"; do
    case "${input}" in
      valid )
        shift 1
        Tyk_Test_Approov_Token_Valid
        exit $?
      ;;

      invalid-signature )
        shift 1
        Tyk_Test_Approov_Token_Invalid_Signature
        exit $?
      ;;

      expired )
        shift 1
        Tyk_Test_Approov_Token_Expired
        exit $?
      ;;

      missing )
        shift 1
        Tyk_Test_Approov_Token_Missing
        exit $?
      ;;

      empty )
        shift 1
        Tyk_Test_Approov_Token_Empty
        exit $?
      ;;

      * )
        Tyk_Test_Approov_Token_Valid
        Tyk_Test_Approov_Token_Invalid_Signature
        Tyk_Test_Approov_Token_Expired
        Tyk_Test_Approov_Token_Missing
        Tyk_Test_Approov_Token_Empty
        exit $?
      ;;
    esac
  done
}

Tyk_Test_Approov_Token_Valid() {
  echo "\n---> Valid Approov Token\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H "Api-Key: ${API_KEY}" \
    -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.u-rlLdZgaYUjUpU_wWi7nzeMgae_IfcT7asu22ptXn0'

  echo
}

Tyk_Test_Approov_Token_Expired() {
  echo "\n---> Expired Approov Token\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjE2NjE1MzAxMjB9.bdl_U893ahMEV5bEp7mPAIkRr53qVA0iuZs0LqvSIho'

  echo
}

Tyk_Test_Approov_Token_Invalid_Signature() {
  echo "\n---> Invalid Signature for the Approov Token\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.u-rlLdZgaYUjUpU_wWi7nasMgae_IfcT7asu22ptXn0'

  echo
}

Tyk_Test_Approov_Token_Missing() {
  echo "\n---> The Approov Token is missing in the request headers\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json'

  echo
}

Tyk_Test_Approov_Token_Empty() {
  echo "\n---> The Approov Token in the request headers is empty\n"

  curl http://${TYK_HOST}:${TYK_PORT}/uuid \
    -i \
    -H 'Content-Type: application/json' \
    -H 'Approov-Token: '

  echo
}


############################
# Tyk Stack
############################

Tyk_Stack() {
  for input in "${@:-}"; do
    case "${input}" in
      up )
        shift 1
        Tyk_Stack_Up "${@}"
        echo "\nTo tail the logs:\n\n ./tyk stack logs --follow tyk-gateway\n"
        exit $?
      ;;

      down )
        shift 1
        sudo docker-compose down
        exit $?
      ;;

      reload )
        shift 1
        Tyk_Stack_Reload
        exit $?
      ;;

      shell )
        shift 1
        sudo docker-compose exec tyk-gateway bash
        exit $?
      ;;

      logs )
        shift 1
        sudo docker-compose logs ${@}
        exit $?
      ;;

      * )
        Show_Help
        exit $?
      ;;
    esac
  done
}

Tyk_Stack_Up() {
  for input in "${@:-}"; do
    case "${input}" in
      gateway )
        shift 1
        Tyk_Stack_Gateway_Up
      ;;

      jwt )
        shift 1
        Tyk_Stack_Up_Api_Jwt
      ;;

      python )
        shift 1
        Tyk_Stack_Up_Api_Python_Plugin
      ;;

      * )
        Show_Help
        exit $?
      ;;
    esac
  done
}

Tyk_Stack_Gateway_Up() {
  sudo docker-compose up --detach tyk-redis tyk-gateway
  # Tyk takes some seconds to get properly initialized, therefore we need to
  # sleep a bit to avoid weird behaviors, like not loading the bundle.zip.
  echo "Waiting 15 seconds to give time for the Tyk API Gateway to be ready to receive commands:"
  for i in $(seq 1 15); do printf "."; sleep 1s; done
  echo
}

Tyk_Stack_Up_Api_Jwt() {
  echo "\n---> Tyk Stack JWT: Bring up the Tyk Gateway and Redis..."
  Tyk_Stack_Gateway_Up

  Tyk_Setup_Jwt_Security_Policy
  Tyk_Setup_Jwt_Api
  Tyk_Stack_Reload
}

Tyk_Stack_Up_Api_Python_Plugin() {

  Tyk_Setup_Python_Plugin_Build_Bundle

  echo "\n---> Tyk Stack Python Plugin: Bring up the Tyk Gateway, Redis and the bundle server..."
  Tyk_Stack_Gateway_Up

  Tyk_Setup_Python_Plugin_Security_Policy
  Tyk_Setup_Python_Plugin_Api

  Tyk_Stack_Reload
}

Tyk_Stack_Reload() {
  echo "\n---> Tyk Stack: Reload the Tyk Gateway..."

  curl -i -H "x-tyk-authorization: ${TYK_GW_SECRET}" -s http://${TYK_HOST}:${TYK_PORT}/tyk/reload/group
  echo
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
  local API_KEY # Value is auto generated and stored in the ./.env file

  local AUTH_HEADER_NAME=Approov-Token

  local SECURITY_POLICY_ID=approov
  local SECURITY_POLICY_NAME=Approov

  . ./.env

  for input in "${@}"; do
    case "${input}" in
      -h | --help | help )
        Show_Help
        exit $?
      ;;

      setup )
        shift 1
        Tyk_Setup "${@}"
        exit $?
      ;;

      test )
        shift 1
        Tyk_Test "${@}"
        exit $?
      ;;

      inspect )
        shift 1
        Tyk_Inspect "${@}"
        exit $?
      ;;

      stack )
        shift 1
        Tyk_Stack "${@}"
        exit $?
      ;;

      up )
        Tyk_Stack "${@}"
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
