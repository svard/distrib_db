defmodule DistribDb do
  use Application

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false
    port = Application.get_env(:distrib_db, DistribDb)[:tcp_port]

    children = [
      # Define workers and child supervisors to be supervised
      # worker(DistribDb.Worker, [arg1, arg2, arg3])
      supervisor(DistribDb.DatabaseSupervisor, []),
      worker(DistribDb.Controller, []),
      supervisor(Task.Supervisor, [[name: DistribDb.TaskSupervisor]]),
      worker(Task, [DistribDb.Tcp, :accept, [port]])
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: DistribDb.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
