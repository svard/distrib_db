defmodule DistribDb.Tcp.CommandTest do
  use ExUnit.Case
  import DistribDb.Tcp.Command

  test "should parse CREATE command" do
    assert parse("CREATE mydb") == {:ok, {:create, "mydb"}}
  end

  test "should parse GET command" do
    assert parse("GET mydb key") == {:ok, {:get, "mydb", "key"}}
  end

  test "should parse PUT command" do
    assert parse("PUT mydb key value") == {:ok, {:put, "mydb", "key", "value"}}
  end

  test "should parse DELETE command" do
    assert parse("DELETE mydb key") == {:ok, {:delete, "mydb", "key"}}
  end
end
