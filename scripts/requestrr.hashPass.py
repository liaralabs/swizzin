#!/usr/bin/python3
# Author: Liara
import sys
def set_access_details(password):
    import uuid
    import base64
    import hashlib
    salt = uuid.uuid4()
    salt_bytes = salt.bytes
    password = str.encode(password)
    hashed_password = hashlib.pbkdf2_hmac('sha1', password, salt_bytes, 10000, dklen=32)
    b64_password = base64.b64encode(hashed_password).decode("utf-8")
    return b64_password, salt

b64_pass, uuid = set_access_details(sys.argv[1])

print(b64_pass)
print(uuid)
