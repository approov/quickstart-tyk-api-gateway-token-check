# Approov Integrations Examples

[Approov](https://approov.io) is an API security solution used to verify that requests received by your backend services originate from trusted versions of your mobile apps, and here you can find a full working example for the Tyk API Gateway that is the base for the Approov [quickstart](/docs/APPROOV_TOKEN_QUICKSTART.md).

For more information about how Approov works and why you should use it you can read the [Approov Overview](/OVERVIEW.md) at the root of this repo.

## Docker Stack

The docker stack provided via the `docker-compose.yml` file in this repo is used for development proposes and if you are familiar with docker then feel free to use it to follow the quickstart before you try it for real in your project.

### Setup Env File

Do not forget to properly setup the `.env` file at the root of this repo before you start the docker stack.

```bash
cp .env.example .env
```

Edit rhe `.env` file and add a dummy secret:

```bash
APPROOV_BASE64_SECRET=h+CX0tOzdAAR9l15bWAqvq7w9olk66daIH+Xk+IAHhVVHszjDzeGobzNnqyRze3lw/WVyWrc2gZfh3XXfBOmww==
```

### Build the Docker Stack

The docker stack is composed by the Tyk API Gateway version `4.1` and Redis version `5.0`.

```bash
sudo docker-compose build
```

### Start the Docker Stack

```bash
sudo docker-compose up --detach
```

Redis may take sometime to be ready to be used by the Tyk API Gateway, therefore wait around 30 to 60 seconds before you setup anything in the Tyk API Gateway.

### Tail the Logs

```bash
sudo docker-compose logs --follow tyk-gateway
```

You can ommit the `tyk-gateway` service to follow the logs of all services declared in the `docker-compose.yml` file.

## The HttpBin API Example

We will create a proxy for httpbin.org where all the API endpoints require a valid and not expired Approov token.

We will use a bash script helper to simplify the usage, while at same time we provide the cURL command being executed by it. You can always see the exact cURL commands being executed by the bash script by invoking it in debug mode `bash -x ./tyk command`.

### Creating the HttpBin API

```bash
./tyk api-setup
```

or

```bash
curl http://localhost:8002/tyk/apis -i -s -H 'x-tyk-authorization: ___YOUR_TYK_SUPER_SECRET_HERE___' -H 'Content-Type: application/json' -X POST -d '{
      "api_id": "httpbin.org",
      "slug": "httpbin",
      "name": "HttpBin",
      "org_id": "1",
      "auth": {
        "auth_header_name": "Approov-Token"
      },
      "definition": {
        "location": "header",
        "key": "x-api-version"
      },
      "version_data": {
        "not_versioned": true,
        "versions": {
          "Default": {
            "name": "Default",
            "use_extended_paths": true
          }
        }
      },
      "proxy": {
        "listen_path": "/",
        "target_url": "https://httpbin.org",
        "strip_listen_path": true
      },
      "active": true,
      "enable_jwt": true,
      "jwt_signing_method": "hmac",
      "jwt_identity_base_field": "iss",
      "jwt_default_policies": [
        "approov"
      ],
      "jwt_source": "h+CX0tOzd...fh3XXfBOmww=="

    }'
```

The output:

```
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 31 Aug 2022 17:52:02 GMT
Content-Length: 53

{"key":"httpbin.org","status":"ok","action":"added"}

```

The important bits in the API definition are the keys `jwt_*` and in the key `auth_header_name`.

### Creating the Tyk Security Policy for Approov

```bash
./tyk create-policy
```

or

```bash
curl http://localhost:8002/tyk/policies -i -s -H 'x-tyk-authorization: ___YOUR_TYK_SUPER_SECRET_HERE___' -H 'Content-Type: application/json' -X POST -d '
      {
        "id": "approov",
        "access_rights": {
          "httpbin.org": {
            "allowed_urls": [],
            "api_id": "httpbin.org",
            "api_name": "HttpBin",
            "versions": [
                "Default"
            ]
          }
        },
        "org_id": "1",
        "active": true,
        "name": "Approov",
        "rate": 0,
        "per": 1,
        "quota_max": -1,
        "state": "active",
        "tags": ["Approov"]
      }'
```

The output:

```text
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 31 Aug 2022 17:59:29 GMT
Content-Length: 49

{"key":"approov","status":"ok","action":"added"}

```

The Tyk security policy for Approov doesn't require rate limiting or quota usage, because the Approov token check guarantees with a very high degree of confidence that incoming requests are from **what** the Tyk API Gateway expects, a genuine and unmodified instance of your mobile app, not one that is under attack or that has been tampered with. Bots will not succeed on accessing the API because they are not able to provide an Approov token, and fake tokens will fail the signature check.

### Reload the Tyk API Gateway

For the changes to take effect you need to reload or restart your Tyk API Gateway:

```bash
./tyk reload
```

or

```bash
curl -i -H 'x-tyk-authorization: ___YOUR_TYK_SUPER_SECRET_HERE___' -s http://localhost:8002/tyk/reload/group
```

```text
HTTP/1.1 200 OK
Content-Type: application/json
Date: Wed, 31 Aug 2022 18:08:57 GMT
Content-Length: 29

{"status":"ok","message":""}
```

Now that we have an API protected with Approov it's time to test it, which we will do in the next section.

### Testing the Approov Integration

Any incoming API request requires a correctly signed and not expired Approov token, thus we will test several scenarios to ensure that the Approov protection works as expected.

The Tyk API Gateway will only forward the API request to the API endpoint `https://httpbin.org/uuid` when the Approov token passes the validation, otherwise the API request will be denied.

#### A valid Approov Token

The Approov token is correctly signed and it's not expired.

```bash
./tyk test-approov-token valid
```

or

```bash
curl http://localhost:8002/uuid -i -H 'Content-Type: application/json' -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.u-rlLdZgaYUjUpU_wWi7nzeMgae_IfcT7asu22ptXn0'
```

The output:

```text
HTTP/1.1 200 OK
Access-Control-Allow-Credentials: true
Access-Control-Allow-Origin: *
Content-Length: 53
Content-Type: application/json
Date: Wed, 31 Aug 2022 18:34:09 GMT
Server: gunicorn/19.9.0
X-Ratelimit-Limit: -1
X-Ratelimit-Remaining: 0
X-Ratelimit-Reset: 0

{
  "uuid": "afaaeb50-8f15-44cd-b1e2-1a1326bbfede"
}
```

#### Approov Token with Invalid Signature

The Approov token provided in the header of the request was signed with a secret not known by the Tyk API Gateway to signal that it cannot trust in the incoming API request.

```bash
./tyk test-approov-token invalid-signature
```

or

```bash
curl http://localhost:8002/uuid -i -H 'Content-Type: application/json' -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjQ3MDg2ODMyMDUuODkxOTEyfQ.u-rlLdZgaYUjUpU_wWi7nasMgae_IfcT7asu22ptXn0'
```

The output:

```text
HTTP/1.1 403 Forbidden
Content-Type: application/json
X-Generator: tyk.io
Date: Wed, 31 Aug 2022 18:40:47 GMT
Content-Length: 64

{
    "error": "Key not authorized:Unexpected signing method."
}
```

#### Approov Token Expired

The Approov token provided in the header of the request was correctly signed with the same secret known by the Tyk API Gateway, but the `exp` claim is in the past, therefore the token **it's expired** and the incoming API request cannot be served.

```bash
./tyk test-approov-token expired
```

or

```bash
curl http://localhost:8002/uuid -i -H 'Content-Type: application/json' -H 'Approov-Token: eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiIsImtpZCI6IlJFUExBQ0VfV0lUSF9ZT1VSX09SR0FOSVpBVElPTl9JRDg2OTZkYmQ4MDYxZjRiNTM5MDExYWU2OGI0ZmZjNzllIn0.eyJpc3MiOiJhcHByb292LmlvIiwicG9sIjoiaHR0cGJpbi5vcmciLCJleHAiOjE2NjE1MzAxMjB9.bdl_U893ahMEV5bEp7mPAIkRr53qVA0iuZs0LqvSIho'
```

The output:

```text
HTTP/1.1 401 Unauthorized
Content-Type: application/json
X-Generator: tyk.io
Date: Wed, 31 Aug 2022 18:43:40 GMT
Content-Length: 56

{
    "error": "Key not authorized: token has expired"
}
```

#### Approov Token Missing

The Approov token isn't present in the headers of the request therefore the incoming API request cannot be served.

```bash
./tyk test-approov-token missing
```

or

```bash
curl http://localhost:8002/uuid -i -H 'Content-Type: application/json'
```

The output:

```text
HTTP/1.1 400 Bad Request
Content-Type: application/json
X-Generator: tyk.io
Date: Wed, 31 Aug 2022 18:49:57 GMT
Content-Length: 46

{
    "error": "Authorization field missing"
}
```

#### Approov Token Empty

The Approov token in the headers of the request is empty therefore the incoming API request cannot be served.

```bash
./tyk test-approov-token empty
```

or

```bash
curl http://localhost:8002/uuid -i -H 'Content-Type: application/json' -H 'Approov-Token: '
```

The output:

```text
HTTP/1.1 400 Bad Request
Content-Type: application/json
X-Generator: tyk.io
Date: Wed, 31 Aug 2022 18:49:57 GMT
Content-Length: 46

{
    "error": "Authorization field missing"
}
```


## Issues

If you find any issue while following our instructions then just report it [here](https://github.com/approov/quickstart-tyk-api-gateway-token-check/issues), with the steps to reproduce it, and we will sort it out and/or guide you to the correct path.


## Useful Links

If you wish to explore the Approov solution in more depth, then why not try one of the following links as a jumping off point:

* [Approov Free Trial](https://approov.io/signup)(no credit card needed)
* [Approov Get Started](https://approov.io/product/demo)
* [Approov QuickStarts](https://approov.io/docs/latest/approov-integration-examples/)
* [Approov Docs](https://approov.io/docs)
* [Approov Blog](https://approov.io/blog/)
* [Approov Resources](https://approov.io/resource/)
* [Approov Customer Stories](https://approov.io/customer)
* [Approov Support](https://approov.io/contact)
* [About Us](https://approov.io/company)
* [Contact Us](https://approov.io/contact)
