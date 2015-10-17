defmodule DistribDb.Database do
  require Logger
  alias DistribDb.DatabaseSupervisor
  use GenServer

  def start_link do
    Logger.debug "Starting database"
    GenServer.start_link(__MODULE__, nil, name: :db_manager)
  end

  def create_local_db(name) do
    GenServer.call(:db_manager, {:new, name})
  end

  def create_local_db(name, expire) do
    GenServer.call(:db_manager, {:new, name})
    Process.send_after(:db_manager, {:expire, name}, (expire*1000))
    :ok
  end

  def drop_local_db(name) do
    stop(name)
    GenServer.call(:db_manager, {:drop, name})
  end

  def restore_local_db(name) do
    Logger.debug "Restoring database #{name}"
    
    db = Node.list
    |> hd
    |> :rpc.call(__MODULE__, :get_db_copy, [name], :timer.seconds(5))
    
    GenServer.call(:db_manager, {:restore, name, db})
  end

  def create_db(name) do
    Logger.debug "Creating db #{name}"
    {results, _bad_nodes} = :rpc.multicall(__MODULE__, :create_local_db, [name], :timer.seconds(5))

    {:ok, hd(results)}
  end

  def create_db(name, expire) do
    Logger.debug "Creating db #{name} with expire timer in #{expire}s"
    {results, _bad_nodes} = :rpc.multicall(__MODULE__, :create_local_db, [name, expire], :timer.seconds(5))

    {:ok, hd(results)}
  end

  def drop_db(name) do
    Logger.debug "Dropping db #{name}"
    :rpc.multicall(__MODULE__, :drop_local_db, [name], :timer.seconds(5))

    :ok
  end

  def get_db(name) do
    GenServer.call(:db_manager, {:get, name})
  end

  def put_local(name, key, value) do
    case get_db(name) do
      nil -> {:error, :db_not_found}
      pid -> GenServer.cast(pid, {:put, key, value})
    end
  end

  def put(name, key, value) do
    Logger.debug "Putting #{key} #{value} in db #{name}"
    {results, _} = :rpc.multicall(__MODULE__, :put_local, [name, key, value], :timer.seconds(5))
    check_ok results
  end

  def get(name, key) do
    case get_db(name) do
      nil -> {:error, :db_not_found}
      pid -> {:ok, GenServer.call(pid, {:get, key})}
    end
  end

  def delete_local(name, key) do
    case get_db(name) do
      nil -> {:error, :db_not_found}
      pid -> GenServer.cast(pid, {:delete, key})
    end
  end

  def delete(name, key) do
    Logger.debug "Deleting #{key} from db #{name}"
    {results, _} = :rpc.multicall(__MODULE__, :delete_local, [name, key], :timer.seconds(5))
    check_ok results
  end

  def stop(name) do
    case get_db(name) do
      nil -> {:error, :db_not_found}
      pid -> GenServer.call(pid, :stop)
    end
  end

  def exist?(name) do
    Logger.debug "Check if db #{name} exist"
    get_db_names |> Enum.member?(name)
  end

  def sync do
    if Enum.count(Node.list) > 0 do
      Node.list
      |> hd
      |> :rpc.call(__MODULE__, :get_db_names, [], :timer.seconds(5))
      |> Enum.each(&restore_local_db/1)
    else
      :not_needed
    end
  end

  def get_db_names do
    GenServer.call(:db_manager, :get)
  end

  def get_db_copy(name) do
    get_db(name) |> GenServer.call(:get)
  end

  defp check_ok(results) do
    if Keyword.has_key?(results, :error) do
      {:error, Keyword.fetch!(results, :error)}
    else
      :ok
    end
  end 

  def init(_) do
    {:ok, Map.new}
  end

  def handle_call({:new, name}, _from, dbs) do
    if Map.has_key?(dbs, name) do
      {:reply, Map.get(dbs, name), dbs}
    else
      case DatabaseSupervisor.start_child(nil) do
        {:ok, pid} ->
          {:reply, pid, Map.put(dbs, name, pid)}
        _ ->
          {:stop, :normal, {:error, "Can't start db"}, dbs}
      end
    end
  end

  def handle_call({:restore, name, db}, _from, dbs) do
    case DatabaseSupervisor.start_child(db) do
      {:ok, pid} ->
        {:reply, pid, Map.put(dbs, name, pid)}
      _ ->
        {:stop, :normal, {:error, "Can't start db"}, dbs}
    end
  end
  
  def handle_call({:get, name}, _from, dbs) do
    {:reply, Map.get(dbs, name), dbs}
  end

  def handle_call(:get, _from, dbs) do
    {:reply, Map.keys(dbs), dbs}
  end

  def handle_call({:drop, name}, _from, dbs) do
    {:reply, :ok, Map.delete(dbs, name)}
  end

  def handle_info({:expire, name}, dbs) do
    Logger.info "Database #{name} expired, dropping it"
    drop_local_db(name)
    {:noreply, dbs}
  end

  def handle_info(_msg, dbs) do
    Logger.warn "Unknown message arrived at database process"
    {:noreply, dbs}
  end
end
