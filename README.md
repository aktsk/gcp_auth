# GCPAuth

[![Build Status](https://travis-ci.org/aktsk/gcp_auth.svg?branch=master)](https://travis-ci.org/aktsk/gcp_auth)
[![Hex.pm](https://img.shields.io/hexpm/v/gcp_auth.svg)](https://hex.pm/packages/gcp_auth)
[![Hex.pm](https://img.shields.io/hexpm/l/gcp_auth.svg)](https://github.com/aktsk/gcp_auth/blob/master/LICENSE)

GCP (Google Cloud Platform) auth library using [Application Default Credentials](https://developers.google.com/identity/protocols/application-default-credentials
).
This is intended to be used for [Server to Server Applications](https://developers.google.com/identity/protocols/OAuth2ServiceAccount).


## Installation and Usage

Add `:gcp_auth` to `application` and `deps` in `mix.exs`.

```elixir
def deps do
  [{:gcp_auth, "~> 0.1"}]
end

def application do
  [applications: [:gcp_auth]]
end
```

And add `:scopes` to your `config.ex`.
The full list of OAuth2 scopes for Google APIs can be seen at https://developers.google.com/identity/protocols/googlescopes

```elixir
config :gcp_auth,
  scopes: ["https://www.googleapis.com/auth/devstorage.read_write"]
```

To get access token, call `GCPAuth.Token.get()`.

```elixir
> GCPAuth.Token.get()
"xxxx.yyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyyy"
```

### Examples

An example for uploading a file to GCS (Google Cloud Storage) is as follows:

```elixir
access_token = GCPAuth.Token.get()
bucket = "your-bucket"
upload_path = "uploads/filename"
uri = %URI{scheme: "https",
           host: "www.googleapis.com",
           path: "/upload/storage/v1/b/#{bucket}/o",
           query: "uploadType=media&predefinedAcl=publicRead&name=#{upload_path}"}
local_path = "path/to/existing/localfile"
body = {:file, local_path}
headers = %{"Authorization" => "Bearer #{access_token}"}
HTTPoison.post(uri, body, headers)
```


## Configuration

### Disabling

To disable GCPAuth at specific environments e.g. `dev` or `test`, set `:enabled` to `false`.

```elixir
config :gcp_auth,
  enabled: false
```

### Overriding Application Default Credentials

By default, GCPAuth uses [ADC (Application Default Credentials)](https://developers.google.com/identity/protocols/application-default-credentials
).
That is to say

1. If the environment variable GOOGLE_APPLICATION_CREDENTIALS is specified, the file is used as the credentials file.
2. If `~/.config/gcloud/application_default_credentials.json` exists, it is used. This wellknown file is created by running `gcloud auth application-default login`.
3. (Not supported for now) If you are running in GAE (Google App Engine), the built-in service account associated with the application will be used.
4. If you are running in GCE (Google Compute Engine), the built-in service account associated with the virtual machine instance will be used.

You can override this by adding `:credentials_file` to `config.ex`.

```elixir
config :gcp_auth,
  credentials_file: "credentials.json",
  scopes: ["https://www.googleapis.com/auth/devstorage.read_write"]
```
