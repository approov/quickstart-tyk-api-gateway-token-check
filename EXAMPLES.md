# Approov Integrations Examples

[Approov](https://approov.io) is an API security solution used to verify that requests received by your backend services originate from trusted versions of your mobile apps, and here you can find a full working examples for the Tyk API Gateway that are the base for the [Approov Quickstarts](QUICKSTARTS.md).

For more information about how Approov works and why you should use it you can read the [Approov Overview](/OVERVIEW.md) at the root of this repo.

## Tyk API Gateway Examples

To learn more about each Tyk API Gateway example you need to read the README for each one at:

* [Tyk API Gateway - Approov JWT](./examples/TYK_GATEWAY_APPROOV_JWT_EXAMPLE.md)
* [Tyk API Gateway - Approov Python Plugin](./examples/TYK_GATEWAY_APPROOV_PYTHON_PLUGIN_EXAMPLE.md)


## Docker Stack

The docker stack provided via the `docker-compose.yml` file in this repo is used for development proposes and if you are familiar with docker then feel free to use it to follow the quickstart before you try it for real in your project.

### Setup Env File

Do not forget to properly setup the `.env` file at the root of this repo before you start the docker stack.

```bash
cp .env.example .env
```

Edit the `.env` file and add a dummy secret:

```bash
APPROOV_BASE64_SECRET=h+CX0tOzdAAR9l15bWAqvq7w9olk66daIH+Xk+IAHhVVHszjDzeGobzNnqyRze3lw/WVyWrc2gZfh3XXfBOmww==
```

This dummy secret was used to sign the valid Approov tokens in the tests that you can run with `./tyk test approov-token`.


### Build the Docker Stack

The docker stack is composed by the Tyk API Gateway version `4.1` and Redis version `5.0`.

```bash
sudo docker-compose build
```

### Start the Docker Stack

The docker stack must be started as per instructions on each example.


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
