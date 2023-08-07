defmodule HttpServer.File do
  require Logger

  def start(port \\ 8000) do
    Logger.info "start File server on #{port} port ..."
    {:ok, listen_socket} = :gen_tcp.listen(port, [:binary, packet: :line, active: false, reuseaddr: true])
    loop_acceptor(listen_socket)
  end

  def loop_acceptor(listen_socket) do
    {:ok, accept_socket} = :gen_tcp.accept(listen_socket)
    handle_server(accept_socket)
    loop_acceptor(listen_socket)
  end

  def handle_server(accept_socket, conn \\%{}) do
    case read_req(accept_socket) do
      {:req_line, method, target, prot_ver} ->
        # connにリクエストライン情報をput
        conn = conn
          |> Map.put(:method, method)
          |> Map.put(:target,target)
          |> Map.put(:prot_ver, prot_ver)
        handle_server(accept_socket, conn)
      {:header_line, header_field, header_val} ->
        # connにヘッダ情報をput
        conn = conn
          |> Map.put(header_field, header_val)
        handle_server(accept_socket, conn)
      :req_end ->
        # responseを返却
        send_resp(accept_socket, conn)
    end
  end

  def read_req(accept_socket) do
    {:ok, raw_msg} = :gen_tcp.recv(accept_socket, 0)
    req_msg = String.trim(raw_msg)

    case String.split(req_msg, " ") do
      # リクエストラインの解析
      [method, target, prot_ver] ->
        {:req_line, method, target, prot_ver}
      # ヘッダの解析
      [header_field, header_val] ->
        {:header_line, header_field, header_val}
      # ヘッダ以降は対応しない
      _ ->
        :req_end
    end
  end

  def send_resp(accept_socket, conn) do
    resp_msg= build_resp_msg(conn)

    :gen_tcp.send(accept_socket, resp_msg)
    :gen_tcp.close(accept_socket)
  end

  def build_resp_msg(conn) do
    target_path = "#{File.cwd!}/priv#{Map.get(conn, :target)}"
    Logger.info "file: #{target_path} ---> exists? [#{File.exists?(target_path)}]"

    {status_code, status_msg, body} = case File.exists?(target_path) do
      true -> {200, "OK", File.read!(target_path)}
      false -> {404, "Not Found", "404 Not Found"}
      _else -> {500, "Internal Server Error", "Ooops!"}
    end

    """
    HTTP/1.1 #{Status_code} #{status_msg}

    #{body}
    """
  end
end
