defmodule JollaCNAPI.Router.Util do
  def get_ip(%{req_headers: req_headers, remote_ip: remote_ip}) do
    headers = Map.new(req_headers)

    case Map.get(headers, "x-forwarded-for", "") do
      forwarded_list when forwarded_list in ["", "127.0.0.1"] ->
        case Map.get(headers, "x-real-ip", "") do
          x_real_ip when x_real_ip in ["", "127.0.0.1"] ->
            case Map.get(headers, "x-remote-addr", "") do
              x_remote_addr when x_remote_addr in ["", "127.0.0.1"] ->
                remote_ip |> Tuple.to_list() |> Enum.join(".")

              x_remote_addr ->
                x_remote_addr
            end

          x_real_ip ->
            x_real_ip
        end

      forwarded_list ->
        forwarded_list
        |> String.split(",")
        |> List.first()
        |> String.trim()
    end
  end
end
