defmodule GCPAuth.OAuth2 do
  @callback get_access_token(struct | nil) :: {:ok, binary, non_neg_integer} | {:error, any}
end
