defmodule DistribDb.Controller do
  require Logger
  alias DistribDb.Register

  def create_db(name) do
    Logger.debug "Creating db #{name}"
    {results, _bad_nodes} = :rpc.multicall(DistribDb.Register, :create_local_db, [name], :timer.seconds(5))

    {:ok, hd(results)}
  end

  def create_db(name, expire) do
    Logger.debug "Creating db #{name} with expire timer in #{expire}s"
    {results, _bad_nodes} = :rpc.multicall(DistribDb.Register, :create_local_db, [name, expire], :timer.seconds(5))

    {:ok, hd(results)}
  end

  def drop_db(name) do
    Logger.debug "Dropping db #{name}"
    :rpc.multicall(DistribDb.Register, :drop_local_db, [name], :timer.seconds(5))

    :ok
  end

  def put(name, key, value) do
    Logger.debug "Putting #{key} #{value} in db #{name}"
    {results, _} = :rpc.multicall(DistribDb.Register, :put_local, [name, key, value], :timer.seconds(5))
    check_ok results
  end

  def delete(name, key) do
    Logger.debug "Deleting #{key} from db #{name}"
    {results, _} = :rpc.multicall(DistribDb.Register, :delete_local, [name, key], :timer.seconds(5))
    check_ok results
  end
  
  def exist?(name) do
    Logger.debug "Check if db #{name} exist"
    Register.get_db_names |> Enum.member?(name)
  end

  def sync do
    if Enum.count(Node.list) > 0 do
      Node.list
      |> hd
      |> :rpc.call(DistribDb.Register, :get_db_names, [], :timer.seconds(5))
      |> Enum.each(&Register.restore_local_db/1)
    else
      :not_needed
    end
  end

  defp check_ok(results) do
    if Keyword.has_key?(results, :error) do
      {:error, Keyword.fetch!(results, :error)}
    else
      :ok
    end
  end
end
