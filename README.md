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
````

For the Windows powershell:

```bash
set APPROOV_ROLE=admin:___YOUR_APPROOV_ACCOUNT_NAME_HERE___
```

Now, get your Approov Secret with the [Approov CLI](https://approov.io/docs/latest/approov-installation/index.html#initializing-the-approov-cli):

```bash
approov secret -get base64
```

Next, update the API you want to protect with the Approov token check, by enabling the Tyk JWT check functionality on the API. Enabling the JWT check will disable your current API key check, therefore you may want to follow instead the [Approov Token Python Plugin Quickstart](/docs/APPROOV_TOKEN_PYTHON_PLUGIN_QUICKSTART.md), that checks the Approov token in the Tyk Middleware on a pre Hook, before user authentication or API Keys checks.


Add the following fields to your API definition to enable the JWT check:

```json
"auth": {
    "auth_header_name": "Approov-Token"
},
"jwt_signing_method": "hmac",
"jwt_identity_base_field": "iss",
"jwt_default_policies": ["approov"],
"jwt_source": "vault://engine/path/to/secret.___APPROOV_BASE64_SECRET_VAR_NAME_HERE___"
```

**NOTE**: Tyk supports more then one mechanism to securely retrieve secrets, therefore you can use the one of your preference to retrieve the Approov secret for the key `jwt_source`, but **never** provide it hard-coded in the JSON configuration. For more information visit their docs page: [Key Value secrets storage for configuration in Tyk](https://tyk.io/docs/tyk-configuration-reference/kv-store/).


Now, create the Tyk security policy for Approov. Add the following to your `policies/policies.json` file:

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

**NOTE:** The Tyk security policy for Approov doesn't require rate limiting or quota usage, because the Approov token check guarantees with a very high degree of confidence that incoming requests are from **what** the Tyk API Gateway expects, a genuine and unmodified instance of your mobile app, not one that is under attack or that has been tampered with. Bots will not succeed on accessing the API because they are not able to provide an Approov token, and fake tokens will fail the signature check. If you still prefer to use rate limiting and quotas then feel free to adjust `rate`, `per`, `quota_max` as you see fit for your use case.

Finally, reload your Tyk API Gateway and confirm that only serves API requests with a correctly signed and not expired `Approov-Token` header.

Not enough details in the bare bones quickstart? No worries, check the [detailed quickstart](docs/APPROOV_TOKEN_QUICKSTART.md) that contain a more comprehensive set of instructions, including how to test the Approov integration.


## More Information

* [Approov Overview](OVERVIEW.md)
* [Detailed Quickstarts](QUICKSTARTS.md)
* [Step by Step Examples](EXAMPLES.md)

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
