from tyk.decorators import *
from gateway import TykGateway as tyk
import jwt # https://github.com/jpadilla/pyjwt/
import base64

from os import getenv

# Token secret value obtained with the Approov CLI tool:
#  - approov secret -get
approov_base64_secret = getenv('APPROOV_BASE64_SECRET')

if approov_base64_secret == None:
    raise ValueError("Missing the value for environment variable: APPROOV_BASE64_SECRET")

APPROOV_SECRET = base64.b64decode(approov_base64_secret)

@Hook
# def MyAuthMiddleware(request, session, metadata, spec):
def VerifyApproovTokenMiddleware(request, session, spec):
    tyk.log("---> Start Approov token check", "info")

    error_message = "Unauthorized"
    status_code = 401

    approov_token = request.get_header("Approov-Token")

    # If we didn't find a token, then reject the request, because it didn't come
    # from a genuine and unmodified version of your mobile app.
    if approov_token == "":
        tyk.log("Approov token empty", "info")
        return request, session

    try:
        # Decode the Approov token explicitly with the HS256 algorithm to avoid
        # the algorithm None attack.
        approov_token_claims = jwt.decode(approov_token, APPROOV_SECRET, algorithms=['HS256'])
        tyk.log("Approov token valid", "info")
        # status_code = 200
        # error_message = ''
        return request, session

    except jwt.ExpiredSignatureError as e:
        tyk.log("Approov token expired", "info")
    except jwt.InvalidTokenError as e:
        tyk.log("Approov token invalid", "info")

    request.object.return_overrides.response_error = error_message
    request.object.return_overrides.response_code = status_code

    tyk.log("<--- Ended Approov token check", "info")

    return request, session
