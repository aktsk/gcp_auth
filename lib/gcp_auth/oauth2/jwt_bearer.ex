defmodule GCPAuth.OAuth2.JWTBearer do
  @moduledoc """
  See https://tools.ietf.org/html/rfc7523
  """
  @behaviour GCPAuth.OAuth2

  @expires_in 60 * 60

  @type t :: %__MODULE__{}
  defstruct [:token_url, :scope, :client_email, :private_key, :private_key_id]

  def get_access_token(%__MODULE__{token_url: token_url,
                                   scope: scope,
                                   client_email: iss,
                                   private_key: private_key,
                                   private_key_id: private_key_id}) do
    unix_now = DateTime.utc_now() |> DateTime.to_unix()
    expires_at = unix_now + @expires_in
    claim_set = %{"iss" => iss,
                  "scope" => scope,
                  "aud" => URI.to_string(token_url),
                  "exp" => expires_at,
                  "iat" => unix_now}
    jwt = JsonWebToken.sign(claim_set, %{alg: "RS256",
                                         key: private_key,
                                         kid: private_key_id})
    payload = URI.encode_query(%{grant_type: "urn:ietf:params:oauth:grant-type:jwt-bearer",
                                 assertion: jwt})
    headers = %{"Content-Type" => "application/x-www-form-urlencoded; charset=utf-8"}
    case HTTPoison.post(token_url, payload, headers) do
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
