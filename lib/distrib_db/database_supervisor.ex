defmodule DistribDb.DatabaseSupervisor do
  require Logger
  alias DistribDb.DatabaseWorker
  use Supervisor

  def start_link do
    Logger.debug "Database supervisor started"
    Supervisor.start_link(__MODULE__, nil, name: :database_supervisor)
  end

  def start_child(db) do
    Supervisor.start_child(:database_supervisor, [db])
  end

  def init(_) do
    supervise([worker(DatabaseWorker, [])], strategy: :simple_one_for_one)
  end
end
