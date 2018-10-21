defmodule JollaCNAPI.DB.Util.Type.JSON do
  @behaviour Ecto.Type

  def type, do: :json

  def cast(any), do: {:ok, any}

  def load(value) do
    result = :jiffy.decode(value, [:use_nil, :return_maps])
    # IO.puts("load #{inspect value} to #{inspect result}")
    result
  end

  def dump(value) do
    # result = :jiffy.encode(value, [:use_nil])
    result = value
    # IO.puts("dump #{inspect value} to #{inspect result}")
    {:ok, result}
  end
end

defmodule JollaCNAPI.DB.Util do
  require Logger

  def all(result, configs) when configs != [] do
    # |> (fn e ->
    #       Logger.debug("#{inspect(e)}")
    #       e
    #     end).()
    result
    |> all([])
    |> Enum.map(fn record -> one_formatter(record, configs) end)
  end

  def all(%{columns: cols, rows: rows}, configs) when configs == [] do
    Enum.map(rows, fn row ->
      cols
      |> Enum.zip(row)
      |> Map.new()
    end)
  end

  def all(result) do
    all(result, [])
  end

  def one(result, configs) when configs != [] do
    case one(result, []) do
      nil ->
        nil

      one_result ->
        one_formatter(one_result, configs)
    end
  end

  def one(result, configs) when configs == [] do
    one(result)
  end

  def one(result = %{num_rows: 1, columns: _cols, rows: _rows}) do
    [single] = all(result)
    single
  end

  def one(%{num_rows: 0}) do
    nil
  end

  def one(%{num_rows: num_rows}) when num_rows > 1 do
    throw("more than one record found")
  end

  def one_formatter(record, configs) do
    datetime_config = Keyword.get(configs, :datetime, nil)
    decimal_config = Keyword.get(configs, :decimal, nil)

    record
    |> Enum.map(fn
      {key, timetuple = {{_, _, _}, {_h, _m, _s, _ms}}} ->
        {
          key,
          timetuple_formatter(timetuple, datetime_config)
        }

      {key, decimal = %Decimal{}} ->
        {key, decimal_formatter(decimal, decimal_config)}

      result = {_key, _value} ->
        result
    end)
    |> Map.new()
  end

  def timetuple_formatter(tt = {{_, _, _}, {_h, _m, _s, _ms}}, nil) do
    tt
  end

  def timetuple_formatter({d = {_, _, _}, {h, m, s, ms}}, :datetime) do
    # IO.puts(ms)
    # |> NaiveDateTime.from_erl!({ms * 1_000, 6})
    {d, {h, m, s}}
    |> NaiveDateTime.from_erl!({ms, 6})
    |> NaiveDateTime.truncate(:second)
  end

  def timetuple_formatter(
        timetuple = {{_, _, _}, {_h, _m, _s, _ms}},
        {datetime_format, :strftime}
      ) do
    timetuple
    |> timetuple_formatter(:datetime)
    |> Timex.format!(datetime_format, :strftime)
  end

  def decimal_formatter(decimal, nil) do
    decimal
  end

  def decimal_formatter(decimal, {:string, precision}) do
    Decimal.with_context(%Decimal.Context{precision: precision}, fn ->
      decimal |> Decimal.plus() |> Decimal.to_string(:normal)
    end)
  end

  def add_timestamps(changeset = %{changes: %{inserted_at: _, updated_at: _}}, _struct) do
    # Logger.debug "1#{inspect changeset}"
    changeset
  end

  def add_timestamps(changeset = %{changes: %{updated_at: _}}, %{inserted_at: s}) when s != nil do
    # Logger.debug "2#{inspect changeset}"
    changeset
  end

  def add_timestamps(changeset = %{changes: changes = %{}}, _struct = %{inserted_at: s})
      when s != nil do
    # Logger.debug "3#{inspect changeset} / struct=#{inspect struct}"
    Map.put(
      changeset,
      :changes,
      Map.put(
        changes,
        :updated_at,
        Timex.now("Asia/Shanghai")
        |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
        |> Timex.parse!("%Y-%m-%d %H:%M:%S", :strftime)
        |> Timex.to_naive_datetime()
      )
    )
  end

  def add_timestamps(changeset = %{changes: changes = %{}}, %{inserted_at: nil}) do
    # Logger.debug "4#{inspect changeset}"
    Map.put(
      changeset,
      :changes,
      Map.merge(changes, %{
        :updated_at =>
          Timex.now("Asia/Shanghai")
          |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
          |> Timex.parse!("%Y-%m-%d %H:%M:%S", :strftime)
          |> Timex.to_naive_datetime(),
        :inserted_at =>
          Timex.now("Asia/Shanghai")
          |> Timex.format!("%Y-%m-%d %H:%M:%S", :strftime)
          |> Timex.parse!("%Y-%m-%d %H:%M:%S", :strftime)
          |> Timex.to_naive_datetime()
      })
    )
  end
end
