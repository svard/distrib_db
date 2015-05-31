defmodule DistribDb.Tcp do
  require Logger
  import Pipe
  alias DistribDb.Tcp.Command
  
  def accept(port) do
    {:ok, socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false])
    Logger.info "Accepting connection on port #{port}"
    loop(socket)
  end

  defp loop(socket) do
    {:ok, client} = :gen_tcp.accept(socket)
    Logger.info "Client connected"
    {:ok, pid} = Task.Supervisor.start_child(DistribDb.TaskSupervisor, fn -> serve(client) end)
    :gen_tcp.controlling_process(client, pid)
    loop(socket)
  end

  defp serve(client) do
    msg = pipe_matching x, {:ok, x}, read_line(client)
    |> Command.parse()
    |> Command.run()

    case msg do
      {:error, :enotconn} ->
        Logger.info "Client disconnected"
        :disconnected
      
      _ ->
        write_line(msg, client)
        serve(client)
    end
  end

  defp read_line(socket) do
    :gen_tcp.recv socket, 0
  end

  defp write_line(line, socket) do
    :gen_tcp.send socket, format_response(line)
  end

  defp format_response({:ok, msg}), do: msg

  defp format_response({:error, :not_found}), do: "NOK NOT FOUND\r\n"

  defp format_response({:error, :unknown_command}), do: "NOK UNKNOWN COMMAND\r\n"

  defp format_response({:error, :db_not_found}), do: "NOK CAN'T FIND DB\r\n"

  defp format_response({:error, _}), do: "NOK ERROR\r\n"
end
