defmodule GrapheneTest do
  use ExUnit.Case, async: true
  doctest Graphene
  @db_api 0

  setup_all context do
    url = "wss://bitshares.openledger.info/ws"
    Graphene.IdStore.start_link
    Graphene.WS.start_link(url)
    %{
      params: %{get_accounts: [@db_api, "get_accounts", [["1.2.0"]]],
     }
    }
  end

  test "call get_accounts params", context do
    params = context.params.get_accounts
    {:ok, result} = Graphene.call(params)

    assert [%{"name" => "committee-account"}] = result
  end

  test "get_accounts" do
    {:ok, result} = Graphene.get_accounts(["1.2.0"])
    assert [%{"name" => "committee-account"}] = result
  end

  test "get_block" do
    {:ok, result} = Graphene.get_block(1)
    assert %{"timestamp" => "2015-10-13T14:12:24"} = result
  end

  @tag :skip
  test "get_transaction" do
    {:ok, result} = Graphene.get_transaction(314,1)
    assert [] = result
  end

  test "get_chain_properties" do
    {:ok, result} = Graphene.get_chain_properties()
    assert %{"chain_id" => "4018d7844c78f6a6c41c6a552b898022310fc5dec06da467ee7905a8dad512c8"} = result
  end

  test "get_global_properties" do
    {:ok, result} = Graphene.get_global_properties()
    assert %{"parameters"  => %{}} = result
  end

  test "get_account_by_name" do
    {:ok, result} = Graphene.get_account_by_name("dan")
    assert %{"id" => "1.2.309"} = result
  end

  test "get_account_references" do
    {:ok, result} = Graphene.get_account_references("1.2.309")
    assert ["1.2.102338"] = result
  end


end
