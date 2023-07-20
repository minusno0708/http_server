defmodule HttpServer.Dumb do
  require Logger

  def start(port \\ 8000) do
    Logger.info "Start dumb server on #{port} port"
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    loop_acceptor(listen_socket)
  end

  def loop_acceptor(listen_socket) do
    {:ok, accept_socket} = :gen_tcp.accept(listen_socket)
    handle_server(accept_socket)
    loop_acceptor(listen_socket)
  end

  def handle_server(accept_socket) do
    case read_line(accept_socket) do
      :closed ->
        Logger.info "handle_server: Server Closed"
        :gen_tcp.close(accept_socket)
      msg ->
        handle_server(accept_socket)
    end
  end

  def read_line(accept_socket) do
    case :gen_tcp.recv(accept_socket, 0) do
      {:ok, msg} ->
        IO.puts String.trim(msg)
      {:error, :closed} ->
        Logger.info "read_line: Server Closed"
        :closed
    end
  end
end
