defmodule DistribDb.DatabaseWorker do
  require Logger
  alias DistribDb.Database
  use GenServer

  def start_link(db) do
    Logger.debug "Worker started"
    GenServer.start_link(__MODULE__, db)
  end

  # def init(nil) do
  #   {:ok, Map.new}
  # end

  def init(expire) when is_number(expire) do
    {:ok, Database.new(expire)}
  end

  def init(db) do
    {:ok, db}
  end

  def handle_cast({:put, key, value}, db) do
    # {:noreply, Map.put(db, key, value)}
    {:noreply, Database.put(db, key, value)}
  end

  def handle_cast({:delete, key}, db) do
    # {:noreply, Map.delete(db, key)}
    {:noreply, Database.delete(db, key)}
  end
  
  def handle_call({:get, key}, _from, db) do
    # {:reply, Map.get(db, key), db}
    {:reply, Database.get(db, key), db}
  end

  def handle_call(:get, _from, db) do
    {:reply, db, db}
  end

  def handle_call(:stop, _from, db) do
    Logger.debug "Stopping database process"
    {:stop, :normal, :ok, db}
  end
end
