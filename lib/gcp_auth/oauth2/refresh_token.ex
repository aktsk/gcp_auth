defmodule GCPAuth.OAuth2.RefreshToken do
  @behaviour GCPAuth.OAuth2

  @type t :: %__MODULE__{}
  defstruct [:token_url, :client_id, :client_secret, :refresh_token]

  def get_access_token(%__MODULE__{token_url: token_url,
                                   client_id: client_id,
                                   client_secret: client_secret,
                                   refresh_token: refresh_token}) do
    payload = URI.encode_query(%{grant_type: "refresh_token",
                                 client_id: client_id,
                                 client_secret: client_secret,
                                 refresh_token: refresh_token})
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
