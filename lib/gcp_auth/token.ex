defmodule GCPAuth.Token do
  @moduledoc """
  See https://developers.google.com/identity/protocols/OAuth2ServiceAccount
  Application Default Credentials: https://developers.google.com/identity/protocols/application-default-credentials
  OAuth2 Scopes: https://developers.google.com/identity/protocols/googlescopes
  """
  use GenServer

  alias GCPAuth.OAuth2.{JWTBearer, RefreshToken, GCEMetadata}

  @type t :: %__MODULE__{
              strategy: JWTBearer | RefreshToken | GCEMetadata,
              client: JWTBearer.t | RefreshToken.t | nil,
              access_token: binary,
              expires_at: non_neg_integer}
  defstruct [:strategy,
             :client,
             :access_token,
             :expires_at]

  @oauth2_token_endpoint_url %URI{scheme: "https",
                                  host: "www.googleapis.com",
                                  path: "/oauth2/v4/token"}

  @spec get() :: binary
  def get() do
    GenServer.call(__MODULE__, :get_access_token)
  end


  def start_link() do
    GenServer.start_link(__MODULE__, [], [name: __MODULE__])
  end

  def init([]) do
    {strategy, client} = strategy_and_client()
    case strategy.get_access_token(client) do
      {:ok, access_token, expires_in} ->
        {:ok, %__MODULE__{strategy: strategy,
                          client: client,
                          access_token: access_token,
                          expires_at: expires_at(expires_in)}}
      {:error, _reason} ->
        raise "Cannot get application default credentials"
    end
  end

  @spec strategy_and_client() :: {JWTBearer, %JWTBearer{}} | {RefreshToken, %RefreshToken{}} | {GCEMetadata, nil}
  defp strategy_and_client() do
    case get_credentials_filename() do
      nil ->
        {GCEMetadata, nil}
      path ->
        path
        |> File.read!()
        |> Poison.decode!()
        |> do_init()
    end
  end

  @spec get_credentials_filename() :: binary | nil
  defp get_credentials_filename() do
    case Application.get_env(:gcp_auth, :credentials_file) do
      nil ->
        case System.get_env("GOOGLE_APPLICATION_CREDENTIALS") do
          nil ->
            well_known_file = get_well_known_file()
            if File.exists?(well_known_file) do
              well_known_file
            else
              nil
            end
          file ->
            file
        end
      file ->
        file
    end
  end

  @spec get_well_known_file() :: binary
  defp get_well_known_file() do
    case System.get_env("CLOUDSDK_CONFIG") do
      nil ->
        case :os.type() do
          {:unix, _osname} ->
            Path.expand("~/.config/gcloud/application_default_credentials.json")
          {:win32, :nt} ->
            case System.get_env("APPDATA") do
              nil ->
                raise "On Windows, APPDATA or CLOUDSDK_CONFIG environment variable must be set."
              appdata_dir ->
                Path.join(appdata_dir, "gcloud/application_default_credentials.json")
            end
        end
      config_dir ->
        Path.join(config_dir, "application_default_credentials.json")
    end
  end

  @spec do_init(map) :: {JWTBearer, %JWTBearer{}} | {RefreshToken, %RefreshToken{}}
  defp do_init(%{"type" => "service_account",
                 "client_email" => client_email,
                 "private_key_id" => private_key_id,
                 "private_key" => private_key_str}) do
    client = %JWTBearer{token_url: @oauth2_token_endpoint_url,
                        scope: fetch_scope!(),
                        client_email: client_email,
                        private_key_id: private_key_id,
                        private_key: JsonWebToken.Algorithm.RsaUtil.private_key(private_key_str)}
    {JWTBearer, client}
  end
  defp do_init(%{"type" => "authorized_user",
                 "client_id" => client_id,
                 "client_secret" => client_secret,
                 "refresh_token" => refresh_token}) do
    client = %RefreshToken{token_url: @oauth2_token_endpoint_url,
                           client_id: client_id,
                           client_secret: client_secret,
                           refresh_token: refresh_token}
    {RefreshToken, client}
  end

  @spec fetch_scope!() :: binary
  defp fetch_scope!() do
    Application.fetch_env!(:gcp_auth, :scopes)
    |> Enum.join(" ")
  end

  def handle_call(:get_access_token, _from, %__MODULE__{strategy: strategy,
                                                        client: client,
                                                        access_token: access_token,
                                                        expires_at: expires_at} = state) do
    unix_now = DateTime.utc_now() |> DateTime.to_unix()
    if unix_now <= expires_at do
      {:reply, access_token, state}
    else
      {:ok, new_access_token, expires_in} = strategy.get_access_token(client)
      {:reply, new_access_token, %{state | access_token: new_access_token,
                                           expires_at: expires_at(expires_in)}}
    end
  end

  @spec expires_at(non_neg_integer) :: non_neg_integer
  defp expires_at(expires_in) do
    unix_now = DateTime.utc_now() |> DateTime.to_unix()
    unix_now + expires_in
  end
end
