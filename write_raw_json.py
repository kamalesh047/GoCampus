import json

raw_json = r'''{
  "type": "service_account",
  "project_id": "gocampus01-e0437",
  "private_key_id": "135401e9a7c3a4c22159be6dd9dee69225eaaa25",
  "private_key": "-----BEGIN PRIVATE KEY-----\nMIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCl14V5Vbv8cOlm\nv+tlmkYRdcOru5IXXEW+6uAcSLLdNFLEPsQjljMKJ8PRnJaCz0reKbhmfIUUIakE\nm+Ml9t25lgqwkXTnNUW+SghXs9cCgWEnNSy8VtJXm3vWbaZVxMf+kmuRlUtvNxCW\nv7csS2tLCYL0Q2qGjTSWczwbISKgdFw6x325FlVclOnaLfEkOSMrSKSK3humzFp7\n6ZcLHMHj4qXcfN8+jU5KHxvakS0e/6NI50iwixtqInqfGKx9rdSVq7qFS3Uli4Uc\naQWk1IZWo+okS2e9BjIJUTO9jPq5k2CyofdoImv5N+5s1+koR3dG140YvI/X7kOz\n3H4uqRvPAgMBAAECggEARITAE7p1Wb444IfotOjBjFMwjdKIcHhiJJgcEfODWttU\nWtpn5SAYZFi7ke31TYRhtVpdYpKN1Rx3HX1eov/U6elw7zSZrTEYaJ9jxQB7lABq\naG2S1xmz/Bg0WQqij4sm6ioKoXKiYQfKJc592qIqaS072rnD2GWc1ZA0xCyzhsEC\nFaQELKh9XGz/TE5c/SwnjPqVrpCFVH037IOUuGR6nI2nM+XbAafhXKBKpdyh0IMb\nM1Tb2xH8fPGkYzOv7JB4k1CTvRnn9gh0PbOPQqVlboxl2cwJdRIjAFpPmTv0NDsa\nMdBjxFR7xI/NIzksOniegB1yx8xyGLm16cJ+IlLYgQKBgQDaARy51/Yyr9ejscoC\Pa6cUQ3obGNAdER+f99bpfhhFLjlfjY0oxCtUfC8hU45fv8hT8bpaEDtIyW9YEJZ\nmOA3cAF4pnz5McEzYemTN6PSzceatjxbGtTOxjzHHYmnYrsdq5KrJy9dKBUvjqvM\nC0ezjeXzqmw5dEG9K5Juymm2jwKBgQDCvwgS0+Ry6oMElntjF23YKPmPAC0fR37i\nEPoZsw4OVlAcWJfkH7Mr9wpZHEuf4CH6u0isz2MKdthFIJUAWA86Fa98MsQcq5UM\nxnWuSmQzB4Fmu8Q7vCY/6C5byAnHYds8aQMzNhpNeyakyFkt3FANdfMTQm7qE6cX\ns7qd/u7mwQKBgQCCoQP7gCKwQJmwJsprCVblp9Pzn27hokmgmzLVkeABHA+mxDfq\n1oMZt+3OqPo0jZqG9Wy1U5kD/3mPvmxDj81aqqzXBLwB/gRMq7DwW/i4SkH+vI/x\n72Pw+uxUS6i+OfTxVGuwTuycn3YCZzUeMOwn9TEDDu2Gh9kUZ1V5OaSalQKBgCGg\nQpCdrbB59a1xHlT50qmkSZL7gM8J1UrLi6OsWxz2olaCpZdqMdHBkjPYwuYUGUnl\n1KKiHIPOCYHGInQwwFBTNj3Htj0NE2tlSSSTC8IT5bALc9Ksph4axQZr/+RBbU19\nBGRvTxNZ1E5Xma5lgB0S5KnKqsQYKJ3bFrn5Lt8BAoGAGGMUoEI3lXaJa9BS0TRT\nK1mZqE1iDQpXPk4ur10HOWG7zOqXiqcLFkrsUwUPZOLtxr91jXQB+xPO0CtxfoMI\nNfgZl9EPxZsJEVs0/xQ28Y3HwI1xaTG88eP2YckKzcUgzG0hZ+er3Yl1WPYW/Pcf\nFdRFSTs+vLxt8GJ8rKYYBxM=\n-----END PRIVATE KEY-----\n",
  "client_email": "firebase-adminsdk-fbsvc@gocampus01-e0437.iam.gserviceaccount.com",
  "client_id": "114013914338063977270",
  "auth_uri": "https://accounts.google.com/o/oauth2/auth",
  "token_uri": "https://oauth2.googleapis.com/token",
  "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
  "client_x509_cert_url": "https://www.googleapis.com/robot/v1/metadata/x509/firebase-adminsdk-fbsvc%40gocampus01-e0437.iam.gserviceaccount.com",
  "universe_domain": "googleapis.com"
}'''

with open(r"C:\Users\KAMALESH\.gemini\antigravity\scratch\gocampus01-e0437-firebase-adminsdk-fbsvc-135401e9a7.json", "w") as f:
    f.write(raw_json)
