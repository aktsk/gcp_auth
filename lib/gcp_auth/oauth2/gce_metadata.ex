defmodule GCPAuth.OAuth2.GCEMetadata do
  @behaviour GCPAuth.OAuth2

  @gce_metadata_token_url %URI{scheme: "http",
                               host: "metadata.google.internal",
                               path: "/computeMetadata/v1/instance/service-accounts/default/token"}

  def get_access_token(nil) do
    headers = %{"Metadata-Flavor" => "Google"}
    case HTTPoison.get(@gce_metadata_token_url, headers) do
      {:ok, %HTTPoison.Response{status_code: 200, body: response_body}} ->
        %{"access_token" => access_token,
          "expires_in" => expires_in,
          "token_type" => "Bearer"} = Poison.decode!(response_body)
        {:ok, access_token, expires_in}
      {:ok, %HTTPoison.Response{} = response} ->
        {:error, response}
      {:error, %HTTPoison.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
