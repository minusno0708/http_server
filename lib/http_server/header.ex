defmodule HttpServer.Header do
  require Logger

  def start(port \\ 8000) do
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    Logger.info "start Header server on #{port} port ..."
    loop_acceptor(listen_socket)
  end

  def loop_acceptor(listen_socket) do
    {:ok, accept_socket} = :gen_tcp.accept(listen_socket)
    handle_server(accept_socket)
    loop_acceptor(listen_socket)
  end

  def handle_server(accept_socket, conn \\ %{}) do
    case read_req(accept_socket) do
      # リクエストラインをput
      {:req_line, method, target, prot_ver} ->
        conn =conn
          |> Map.put(:method, method)
          |> Map.put(:target, target)
          |> Map.put(:prot_ver, prot_ver)
        handle_server(accept_socket, conn)
      # ヘッダをput
      {:header_line, header_field, header_val} ->
        conn = conn
          |> Map.put(:header_field, header_val)
        handle_server(accept_socket, conn)
      # responseを返却
      :req_end ->
        send_resp(accept_socket, conn)
    end
  end

  def read_req(accept_socket) do
    {:ok, raw_msg} = :gen_tcp.recv(accept_socket, 0)
    req_msg = String.trim(raw_msg)

    case String.split(req_msg, " ") do
      # リクエストラインを解析
      [method, target, prot_ver] ->
        {:req_line, method, target, prot_ver}
      # ヘッダを解析
      [header_field, header_val] ->
        {:header_line, header_field, header_val}
      # ヘッダ以降
      _ ->
        :req_end
    end
  end

  def send_resp(accept_socket, conn) do
    resp_msg = build_resp_msg(conn)

    :gen_tcp.send(accept_socket, resp_msg)
    :gen_tcp.close(accept_socket)
  end

  def build_resp_msg(conn) do
    msg = inspect(conn)

    """
    HTTP/1.1 200 OK
    Content-Length: #{String.length(msg)}

    #{msg}
    """
  end
end
