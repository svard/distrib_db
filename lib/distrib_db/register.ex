defmodule DistribDb.Register do
  require Logger
  alias DistribDb.DatabaseSupervisor
  alias DistribDb.Database
  use GenServer

  def start_link do
    Logger.debug "Starting database"
    GenServer.start_link(__MODULE__, nil, name: :db_manager)
  end

  def create_local_db(name) do
    GenServer.call(:db_manager, {:new, name, 0})
  end

  def create_local_db(name, expire) do
    GenServer.call(:db_manager, {:new, name, expire})
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

  def get_db(name) do
    GenServer.call(:db_manager, {:get, name})
  end

  def put_local(name, key, value) do
    case get_db(name) do
      nil -> {:error, :db_not_found}
      pid -> GenServer.cast(pid, {:put, key, value})
    end
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

  def stop(name) do
    case get_db(name) do
      nil -> {:error, :db_not_found}
      pid -> GenServer.call(pid, :stop)
    end
  end

  def get_db_names do
    GenServer.call(:db_manager, :get)
  end

  def get_db_copy(name) do
    get_db(name) |> GenServer.call(:get)
  end

  def init(_) do
    {:ok, Map.new}
  end

  def handle_call({:new, name, expire}, _from, dbs) do
    if Map.has_key?(dbs, name) do
      {:reply, Map.get(dbs, name), dbs}
    else
      case DatabaseSupervisor.start_child(expire) do
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
        if db.expires_at > 0 do
          Logger.debug "Restoring expire timer, will expire in #{(Database.expire_in(db))}s"
          Process.send_after(:db_manager, {:expire, name}, (Database.expire_in(db)*1000))
        end
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
    Map.get(dbs, name)
    |> GenServer.call(:stop)
    {:noreply, Map.delete(dbs, name)}
  end

  def handle_info(_msg, dbs) do
    Logger.warn "Unknown message arrived at database process"
    {:noreply, dbs}
  end
end
