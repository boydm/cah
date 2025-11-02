defmodule Cah.Ca.Hex do

  import IEx

  @app Mix.Project.config()[:app]
  # load the NIF
  @compile {:autoload, false}
  @on_load :load_nifs
  @doc false
  def load_nifs do
    :ok =
      @app
      |> :code.priv_dir()
      |> :filename.join(~c"ca_hex")
      |> :erlang.load_nif(0)
  end


  @max_value 63


  def build( width, height ) do

    # create the starter bin
    bin = :binary.copy(<<0>>, width * height)

    {:cah, width, height, bin}
  end

# cah = Cah.Ca.Hex.build 3, 3
# cah = Cah.Ca.Hex.put! cah, 1, 1, 1
# Cah.Ca.Hex.get cah, 1, 1
# cah = Cah.Ca.Hex.step cah

  def get( {:cah, width, height, bin}, x, y ) do
    cond do
      x >= width -> {:error, :x}
      y >= height -> {:error, :y}
      true -> nif_get( bin, width, x, y )
    end
  end
  defp nif_get(_, _, _, _), do: :erlang.nif_error("Did not find nif_get")

  def put( {:cah, width, height, bin} = cah, x, y, v ) do
    cond do
      v < 0 -> {:error, :v}
      v >= @max_value -> {:error, :v}
      x < 0 -> {:error, :x}
      x >= width -> {:error, :x}
      y < 0 -> {:error, :y}
      y >= height -> {:error, :y}
      true -> {:ok, {:cah, width, height, nif_put(bin, width, x, y, v)}}
    end
  end
  def put!( {:cah, width, height, bin} = cah, x, y, v ) do
    cond do
      v < 0 -> raise "bad value"
      v > @max_value -> raise "bad value"
      x < 0 -> raise "bad x"
      x >= width -> raise "bad x"
      y < 0 -> raise "bad y"
      y >= height -> raise "bad y"
      true -> {:cah, width, height, nif_put(bin, width, x, y, v)}
    end
  end
  defp nif_put(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_put")

  def step({:cah, width, height, bin}) do
    num_cores = cpu_cores()
    out = :binary.copy(<<0>>, width * height)
    # nif_step(bin, width, height, out, y_start, y_steps)
    nif_step(bin, width, height, out, 0, height)
    {:cah, width, height, out}
  end
  defp nif_step(_, _, _, _, _, _), do: :erlang.nif_error("Did not find nif_step")

  def rot6l(n), do: nif_rot6l(n)
  defp nif_rot6l(_), do: :erlang.nif_error("Did not find rot6l")

  def rot6r(n), do: nif_rot6r(n)
  defp nif_rot6r(_), do: :erlang.nif_error("Did not find rot6r")

  def empty(), do: nif_empty()
  defp nif_empty(), do: :erlang.nif_error("Did not find nif_empty")

  def full(), do: nif_full()
  defp nif_full(), do: :erlang.nif_error("Did not find nif_full")


  def dot( {:cah, w, _h, ca} = cah, x, y, r ) do
    # ca = nif_dot( ca, w, trunc(x), trunc(y), trunc(r) )
    # {:cah, w, _h, ca}

    cah
    |> put!( x, y, 63 )
  end
  # defp nif_dot(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_dot")

  def render( {:mutable_bitmap, {bw, bh, :g}, pixels} = bitmap, {:cah, cw, ch, ca} )
  when bw == cw and bh == ch do
    nif_render( pixels, ca, bw, bh )
    bitmap
  end
  defp nif_render(_, _, _, _), do: :erlang.nif_error("Did not find nif_render")


  # build and display the main rules table
  def table() do
    Enum.reduce(0..63, [], fn(n,acc) ->
      [ case n do
        11 -> 38
        13 -> 22
        19 -> 37
        21 -> 42
        22 -> 13
        25 -> 52
        26 -> 44
        37 -> 19
        38 -> 11
        41 -> 50
        42 -> 21
        44 -> 26
        50 -> 41
        52 -> 25
        _ -> n #|> rot6r() |> rot6r() |> rot6r()
      end | acc ]
    end)
    |> Enum.reverse()
    |> Enum.each(fn(n) -> IO.write("#{n}, ") end)
  end


  defp cpu_cores() do
    :erlang.system_info(:schedulers_online)
  end

end


# Enum.each(1..63, fn(n) -> IO.write("#{Cah.Ca.Hex.count_ones(n)}, ") end)


#iex(2)> Enum.each(0..63, fn(n) -> IO.puts(n) end)
