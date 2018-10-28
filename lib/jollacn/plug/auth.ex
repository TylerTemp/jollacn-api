defmodule JollaCNAPI.Plug.Auth do
  # defmodule IncompleteRequestError do
  #   @moduledoc """
  #   Error raised when a required field is missing.
  #   """
  #
  #   defexception message: "", plug_status: 400
  # end

  require Logger

  def init(options) do
    # IO.inspect(options)
    # IO.inspect(Map.new(options))
    %{path: _} = Map.new(options)
  end

  def call(
        %Plug.Conn{request_path: request_path, method: method, req_headers: req_headers} = conn,
        %{path: pathes}
      ) do
    # request_path: /post
    # method: GET
    case get_matched_path(request_path, pathes) do
      nil ->
        conn

      %{method: ^method, permission: permission_info} ->
        case Map.new(req_headers) do
          %{"authorization" => "Bearer " <> jwt_token} ->
            case String.split(jwt_token, ".") do
              [b64_header, b64_payload, sign] ->
                secret = Application.fetch_env!(:jollacn_api, :jwt_secret)

                check_sign =
                  :sha256
                  |> :crypto.hmac(secret, "#{b64_header}.#{b64_payload}")
                  |> Base.encode16()

                if check_sign != sign do
                  conn
                  |> Plug.Conn.put_resp_header("Content-Type", "application/json")
                  |> Plug.Conn.send_resp(
                    401,
                    :jiffy.encode(%{"message" => "sign failed"}, [
                      :use_nil
                    ])
                  )
                else
                  [
                    %{
                      "alg" => "HS256",
                      "typ" => "JWT"
                    },
                    %{"permission" => user_permissions, "exp" => jwt_expire_timestamp} = user
                  ] =
                    Enum.map([b64_header, b64_payload], fn b64url ->
                      b64url
                      |> Base.url_decode64!(padding: false)
                      |> :jiffy.decode([
                        :use_nil,
                        :return_maps
                      ])
                    end)

                  is_expired = jwt_expire_timestamp - Timex.to_unix(Timex.now()) < 0

                  must_need_permissions = Map.fetch!(permission_info, :must)

                  laked_permissions =
                    Enum.filter(must_need_permissions, fn must_need_permission ->
                      must_need_permission not in user_permissions
                    end)

                  cond do
                    is_expired ->
                      conn
                      |> Plug.Conn.put_resp_header("Content-Type", "application/json")
                      |> Plug.Conn.send_resp(
                        401,
                        :jiffy.encode(
                          %{"message" => "token expired, please login again"},
                          [
                            :use_nil
                          ]
                        )
                      )
                      |> Plug.Conn.halt()

                    laked_permissions != [] ->
                      conn
                      |> Plug.Conn.put_resp_header("Content-Type", "application/json")
                      |> Plug.Conn.send_resp(
                        403,
                        :jiffy.encode(
                          %{"message" => "need permission #{Enum.join(laked_permissions, ",")}"},
                          [
                            :use_nil
                          ]
                        )
                      )
                      |> Plug.Conn.halt()

                    true ->
                      Logger.info("user #{inspect(user)} #{method} #{request_path}")
                      conn
                  end
                end

              _ ->
                conn
                |> Plug.Conn.put_resp_header("Content-Type", "application/json")
                |> Plug.Conn.send_resp(
                  400,
                  :jiffy.encode(%{"message" => "unparseable authorization #{jwt_token}"}, [
                    :use_nil
                  ])
                )
                |> Plug.Conn.halt()
            end

          %{"authorization" => broken_token} ->
            conn
            |> Plug.Conn.put_resp_header("Content-Type", "application/json")
            |> Plug.Conn.send_resp(
              400,
              :jiffy.encode(%{"message" => "unrecognizable authorization #{broken_token}"}, [
                :use_nil
              ])
            )
            |> Plug.Conn.halt()

          _ ->
            conn
            |> Plug.Conn.put_resp_header("Content-Type", "application/json")
            |> Plug.Conn.send_resp(
              401,
              :jiffy.encode(%{"message" => "unauthorized"}, [
                :use_nil
              ])
            )
            |> Plug.Conn.halt()
        end

      {_method, _matched_path} ->
        conn
    end
  end

  defp get_matched_path(request_path, path_info) do
    # request_path_no_ending_slah = path_no_ending_slah(request_path)
    Enum.find(path_info, fn %{path: opt_path} ->
      path_match(request_path, opt_path)
    end)
  end

  defp path_match(path, path) do
    true
  end

  defp path_match(path_1, path_2) do
    path_1_norm =
      if String.ends_with?(path_1, "/") do
        String.slice(path_1, 0, String.length(path_1) - 1)
      else
        path_1
      end

    path_2_norm =
      if String.ends_with?(path_2, "/") do
        String.slice(path_2, 0, String.length(path_2) - 1)
      else
        path_2
      end

    path_1_norm == path_2_norm
  end
end
