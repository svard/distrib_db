defmodule DistribDb.DatabaseTest do
  use ExUnit.Case
  import DistribDb.Database

  setup_all do
    create_db "test"

    on_exit fn ->
      drop_db "test"
    end

    {:ok, db: "test"}
  end

  test "should put a value in the database", context do
    assert put(context[:db], :key, 42) == :ok
  end

  test "should get a value from the database", context do
    put(context[:db], :key, 42)
    assert get(context[:db], :key) == {:ok, 42}
  end

  test "should delete a value from the database", context do
    put(context[:db], :key, 42)
    assert delete(context[:db], :key) == :ok
    assert get(context[:db], :key) == {:ok, nil}
  end

  test "should return an error if the database doesn't exist" do
    assert put("unknown", :key, 42) == {:error, :db_not_found}
    assert get("unknown", :key) == {:error, :db_not_found}
    assert delete("unknown", :key) == {:error, :db_not_found}
  end

  test "should return all created databases", context do
    assert get_db_names == [context[:db]]
    create_db "test1"
    create_db "test2"
    assert get_db_names == [context[:db], "test1", "test2"]
    drop_db "test1"
    drop_db "test2"
  end

  test "should drop a database", context do
    create_db "temp"
    assert get_db_names == ["temp", context[:db]]
    drop_db "temp"
    assert get_db_names == [context[:db]]
  end
end
