defmodule Graphene do
  use Application
  alias Graphene.{IdStore, WS}
  @db_api 0

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    url = Application.get_env(:graphene_client_ex, :url)

    unless url, do: throw("Graphene WS url is NOT configured.")

    # Define workers and child supervisors to be supervised
    children = [
      worker(IdStore, []),
      worker(Graphene.WS, [url])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Graphene.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def call(params) do
    id = gen_id()
    IdStore.put(id, {self(), params})
    send_jsonrpc_call(id, params)

    response = receive do
      {:ws_response, {_, _, response}} -> response
    end

    case response["error"] do
      nil -> {:ok, response["result"]}
      _ -> {:error, response["error"]}
    end
  end

  # Accounts
  def get_accounts(account_list) do
    call [@db_api, "get_accounts", [account_list]]
  end

  def get_account_by_name(name) do
    call_db "get_account_by_name", [name]
  end

  @doc """
  Return
  all accounts that referr to the key or account id in their owner or active authorities.
  """
  def get_account_references(id) do
    call_db "get_account_references", [id]
  end

  @doc """
  Get a list of accounts by name.

  Return
  The accounts holding the provided names
  Parameters
  account_names -
  Names of the accounts to retrieve
  """
  def lookup_account_names(id) do
    call_db "get_account_references", [id]
  end

  @doc """
  Return
  Map of account names to corresponding IDs
  Parameters
  lower_bound_name -
  Lower bound of the first name to return
  limit -
  Maximum number of results to return must not exceed 1000
  """
  def lookup_accounts(lower_bound_name, limit) do
    call_db "lookup_accounts", [lower_bound_name, limit]
  end

  def get_account_count() do
    call_db "get_account_count", []
  end
  
  def get_block(block_height) do
    call [@db_api, "get_block", [block_height]]
  end

  def get_transaction(block_height, trx_in_block) do
     call [@db_api, "get_transaction", [block_height, trx_in_block]]
  end

  def get_chain_properties() do
     call [@db_api, "get_chain_properties", []]
  end

  def get_global_properties() do
     call [@db_api, "get_global_properties", []]
  end

  def call_db(method_name, method_params) do
     call [@db_api, method_name, method_params]
  end

  @doc """
    Sends an event to the WebSocket server
  """
  defp send_jsonrpc_call(id, params) do
    send Graphene.WS, {:send, %{jsonrpc: "2.0", id: id, params: params, method: "call"}}
  end

  defp gen_id do
    round(:rand.uniform * 1.0e16)
  end


end
