defmodule DistribDb.Tcp.Command do
  alias DistribDb.Database
  
  def parse(line) do
    case String.split(line, " ") do
      ["CREATE", db] -> {:ok, {:create, String.strip(db)}}

      ["DROP", db] -> {:ok, {:drop, String.strip(db)}}

      ["GET", db, key] -> {:ok, {:get, String.strip(db), String.strip(key)}}

      ["PUT", db, key, value] -> {:ok, {:put, String.strip(db), String.strip(key), String.strip(value)}}

      ["DELETE", db, key] -> {:ok, {:delete, String.strip(db), String.strip(key)}}
      
      _ -> {:error, :unknown_command}
    end
  end

  def run({:create, db}) do
    Database.create_db db
    {:ok, "OK\r\n"}
  end

  def run({:drop, db}) do
    Database.drop_db db
    {:ok, "OK\r\n"}
  end

  def run({:put, db, key, value}) do
    case Database.put db, key, value do
      :ok -> {:ok, "OK\r\n"}
      {:error, _} = err -> err
    end
  end

  def run({:get, db, key}) do
    case Database.get db, key do
      {:ok, value} -> {:ok, "OK #{value}\r\n"}
      {:error, _} = err -> err
    end
  end

  def run({:delete, db, key}) do
    case Database.delete db, key do
      :ok -> {:ok, "OK\r\n"}
      {:error, _} = err -> err
    end
  end

  def run(_) do
    {:error, :error}
  end
end
