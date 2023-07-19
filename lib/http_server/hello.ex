defmodule HttpServer.Hello do
  require Logger

  def start(port \\ 8000) do
    Logger.info "Start Hello Server on #{port}"
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    loop_acceptor(listen_socket)
  end

  def loop_acceptor(listen_socket) do
    {:ok, accept_socket} = :gen_tcp.accept(listen_socket)
    handle_server(accept_socket)
    loop_acceptor(listen_socket)
  end

  def handle_server(accept_sock) do
    case read_req(accept_sock) do
      {:req_line, _method, _target, _prot_ver} ->
        handle_server(accept_sock)
      {:header_line, _header_field, _header_val} ->
        handle_server(accept_sock)
      :req_end ->
        send_resp(accept_sock)
    end
  end

  def read_req(accept_socket) do
    {:ok, raw_msg} = :gen_tcp.recv(accept_socket, 0)
    req_msg = String.trim(raw_msg)

    case String.split(req_msg, " ") do
      # リクエスト
      [method, target, prot_ver] ->
        {:req_line, method, target, prot_ver}
      # ヘッダ
      [header_field, header_val] ->
        {:header_line, header_field, header_val}
      # ヘッダ以降
      _body ->
        :req_end
    end
  end

  def send_resp(accept_socket) do
    msg = "Hello, Elixir"
    resp_msg = """
      HTTP/1.1 200 OK
      Content-Length: #{String.length(msg)}

      #{msg}
    """
    :gen_tcp.send(accept_socket, resp_msg)
    :gen_tcp.close(accept_socket)
  end
end
