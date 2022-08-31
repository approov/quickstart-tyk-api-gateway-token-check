# Approov QuickStart - TYK API GATEWAY

[Approov](https://approov.io) is an API security solution used to verify that requests received by your backend services originate from trusted versions of your mobile apps.

This repo implements the Approov server-side request verification code for the Tyk API Gateway, which performs the verification check before allowing valid traffic to be processed by the API endpoint.


## Approov Integration Quickstart

The quickstart was tested with the following Operating Systems:

* Ubuntu 20.04
* MacOS Big Sur
* Windows 10 WSL2 - Ubuntu 20.04

First, setup the [Approov CLI](https://approov.io/docs/latest/approov-installation/index.html#initializing-the-approov-cli).

Now, register the API domain for which Approov will issues tokens:

```bash
approov api -add api.example.com
```

Next, enable your Approov `admin` role with:

```bash
eval `approov role admin`
```

Now, get your Approov Secret with the [Approov CLI](https://approov.io/docs/latest/approov-installation/index.html#initializing-the-approov-cli):

```bash
approov secret -get base64
```

Next, update the API you want to protect with the Approov token check, by enabling the Tyk JWT check functionality on the API. Add the following fields to your API definition:

```json
"auth": {
    "auth_header_name": "Approov-Token"
},
"jwt_signing_method": "hmac",
"jwt_identity_base_field": "iss",
"jwt_default_policies": ["approov"],
"jwt_source": "___YOUR_APPROOV_BASE64_SECRET_HERE___"
```

**NOTE**: Enabling the JWT check will disable your current API key check, therefore if this approach for the Approov integration doesn't fit in your use case then please [contact us](https://approov.io/contact) to discuss alternative integrations of Approov in the Tyk API Gateway.

Now, create the security policy for Approov. Add the following to your `policies/policies.json` file:

```json
{
    "approov": {
      "access_rights": {
        "___YOUR_API_ID_HERE___": {
          "allowed_urls": [],
          "api_id": "___YOUR_API_ID_HERE___",
          "api_name": "___YOUR_API_NAME_HERE___}",
          "versions": [
              "Default"
          ]
        }
      },
      "org_id": "___YOUR_ORG_ID_HERE___",
      "active": true,
      "name": "Approov",
      "rate": 0,
      "per": 1,
      "quota_max": -1,
      "state": "active",
      "tags": ["Approov"]
    }
}
```

**NOTE:** We recommend to disable rate limits and quotas for the Approov token check, because when an Approov token check is valid the API request comes from a trusted mobile app. If you still prefer to use rate limiting and quotas then feel free to adjust `rate`, `per`, `quota_max` as you see fit for your use case.

Finally, reload your Tyk API Gateway and you will see that API requests without a correctly signed and not expired `Approov-Token` header will fail.

Not enough details in the bare bones quickstart? No worries, check the [detailed quickstart](docs/APPROOV_TOKEN_QUICKSTART.md) that contain a more comprehensive set of instructions, including how to test the Approov integration.


## More Information

* [Approov Overview](OVERVIEW.md)
* [Detailed Quickstart](docs/APPROOV_TOKEN_QUICKSTART.md)
* [Examples](EXAMPLES.md)

### System Clock

In order to correctly check for the expiration times of the Approov tokens is very important that the backend server is synchronizing automatically the system clock over the network with an authoritative time source. In Linux this is usually done with a NTP server.


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
