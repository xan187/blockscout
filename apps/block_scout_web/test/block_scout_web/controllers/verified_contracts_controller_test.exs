defmodule BlockScoutWeb.VerifiedContractsControllerTest do
  use BlockScoutWeb.ConnCase

  import BlockScoutWeb.Routers.WebRouter.Helpers, only: [verified_contracts_path: 2, verified_contracts_path: 3]

  alias Explorer.Chain.SmartContract

  alias Explorer.Chain.Cache.Counters.{
    ContractsCount,
    NewContractsCount,
    NewVerifiedContractsCount,
    VerifiedContractsCount
  }

  describe "GET index/2" do
    test "returns 200", %{conn: conn} do
      start_supervised!(ContractsCount)
      ContractsCount.consolidate()
      start_supervised!(NewContractsCount)
      NewContractsCount.consolidate()
      start_supervised!(NewVerifiedContractsCount)
      NewVerifiedContractsCount.consolidate()
      start_supervised!(VerifiedContractsCount)
      VerifiedContractsCount.consolidate()

      conn = get(conn, verified_contracts_path(conn, :index))

      assert html_response(conn, 200)
    end

    test "returns all contracts", %{conn: conn} do
      insert_list(4, :smart_contract)

      conn = get(conn, verified_contracts_path(conn, :index), %{"type" => "JSON"})

      items = Map.get(json_response(conn, 200), "items")

      assert length(items) == 4
    end

    test "returns next page of results based on last verified contract", %{conn: conn} do
      insert_list(50, :smart_contract)

      contract = insert(:smart_contract)

      conn =
        get(conn, verified_contracts_path(conn, :index), %{
          "type" => "JSON",
          "smart_contract_id" => Integer.to_string(contract.id)
        })

      items = Map.get(json_response(conn, 200), "items")

      assert length(items) == 50
    end

    test "next_page_path exist if not on last page", %{conn: conn} do
      %SmartContract{id: id} =
        60
        |> insert_list(:smart_contract)
        |> Enum.sort_by(& &1.id, :asc)
        |> Enum.fetch!(10)

      conn = get(conn, verified_contracts_path(conn, :index), %{"type" => "JSON"})

      expected_path =
        verified_contracts_path(conn, :index,
          id: id,
          items_count: "50"
        )

      assert Map.get(json_response(conn, 200), "next_page_path") == expected_path
    end

    test "next_page_path is empty if on last page", %{conn: conn} do
      insert(:smart_contract)

      conn = get(conn, verified_contracts_path(conn, :index), %{"type" => "JSON"})

      refute conn |> json_response(200) |> Map.get("next_page_path")
    end

    test "returns solidity contracts", %{conn: conn} do
      insert(:smart_contract, is_vyper_contract: true, language: nil)

      %SmartContract{address_hash: solidity_hash} =
        insert(:smart_contract, is_vyper_contract: false, language: nil)

      path =
        verified_contracts_path(conn, :index, %{
          "filter" => "solidity",
          "type" => "JSON"
        })

      conn = get(conn, path)

      [smart_contracts_tile] = json_response(conn, 200)["items"]

      assert String.contains?(smart_contracts_tile, "data-identifier-hash=\"#{to_string(solidity_hash)}\"")
    end

    test "returns vyper contract", %{conn: conn} do
      %SmartContract{address_hash: vyper_hash} =
        insert(:smart_contract, is_vyper_contract: true, language: nil)

      insert(:smart_contract, is_vyper_contract: false, language: nil)

      path =
        verified_contracts_path(conn, :index, %{
          "filter" => "vyper",
          "type" => "JSON"
        })

      conn = get(conn, path)

      [smart_contracts_tile] = json_response(conn, 200)["items"]

      assert String.contains?(smart_contracts_tile, "data-identifier-hash=\"#{to_string(vyper_hash)}\"")
    end

    test "returns yul contract", %{conn: conn} do
      %SmartContract{address_hash: yul_hash} =
        insert(:smart_contract, abi: nil, language: nil)

      insert(:smart_contract, language: nil)

      path =
        verified_contracts_path(conn, :index, %{
          "filter" => "yul",
          "type" => "JSON"
        })

      conn = get(conn, path)

      [smart_contracts_tile] = json_response(conn, 200)["items"]

      assert String.contains?(smart_contracts_tile, "data-identifier-hash=\"#{to_string(yul_hash)}\"")
    end

    test "returns search results by name", %{conn: conn} do
      insert(:smart_contract)
      insert(:smart_contract)
      insert(:smart_contract)
      contract_name = "qwertyufhgkhiop"
      %SmartContract{address_hash: hash} = insert(:smart_contract, name: contract_name)

      path =
        verified_contracts_path(conn, :index, %{
          "search" => contract_name,
          "type" => "JSON"
        })

      conn = get(conn, path)

      [smart_contracts_tile] = json_response(conn, 200)["items"]

      assert String.contains?(smart_contracts_tile, "data-identifier-hash=\"#{to_string(hash)}\"")
    end

    test "returns search results by address", %{conn: conn} do
      insert(:smart_contract)
      insert(:smart_contract)
      insert(:smart_contract)
      %SmartContract{address_hash: hash} = insert(:smart_contract)

      path =
        verified_contracts_path(conn, :index, %{
          "search" => to_string(hash),
          "type" => "JSON"
        })

      conn = get(conn, path)

      [smart_contracts_tile] = json_response(conn, 200)["items"]

      assert String.contains?(smart_contracts_tile, "data-identifier-hash=\"#{to_string(hash)}\"")
    end
  end
end
