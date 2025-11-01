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
      v >= @max_value -> raise "bad value"
      x < 0 -> raise "bad x"
      x >= width -> raise "bad x"
      y < 0 -> raise "bad y"
      y >= height -> raise "bad y"
      true -> {:cah, width, height, nif_put(bin, width, x, y, v)}
    end
  end
  defp nif_put(_, _, _, _, _), do: :erlang.nif_error("Did not find nif_put")

  def step({:cah, width, height, bin}) do
    out = :binary.copy(<<0>>, width * height)
    nif_step(bin, width, height, out)
    # pry()
    {:cah, width, height, out}
  end
  defp nif_step(_, _, _, _), do: :erlang.nif_error("Did not find nif_step")

  def rot6l(n), do: nif_rot6l(n)
  defp nif_rot6l(_), do: :erlang.nif_error("Did not find rot6l")

  def rot6r(n), do: nif_rot6r(n)
  defp nif_rot6r(_), do: :erlang.nif_error("Did not find rot6r")

  def empty(), do: nif_empty()
  defp nif_empty(), do: :erlang.nif_error("Did not find nif_empty")

  def full(), do: nif_full()
  defp nif_full(), do: :erlang.nif_error("Did not find nif_full")

  # def get( bin, x, y ), do: :binary.at(bin, x * y)
  # def put( bin, x, y ), do: :binary.at(bin, x * y)


  # n = Cah.Ca.Hex.rot6l n
  # n = Cah.Ca.Hex.rot6r n


  def render( {:mutable_bitmap, {bw, bh, :g}, pixels} = bitmap, {:cah, cw, ch, ca} )
  when bw == cw and bh == ch do
    nif_render( pixels, ca, bw, bh )
    bitmap
  end
  defp nif_render(_, _, _, _), do: :erlang.nif_error("Did not find nif_render")


  # import Bitwise
  # def count_ones(n, acc \\ 0)
  # def count_ones(0, acc), do: acc
  # def count_ones(n, acc) when n > 0 do
  #   count_ones(n >>> 1, acc + (n &&& 1))
  # end

end


# Enum.each(1..63, fn(n) -> IO.write("#{Cah.Ca.Hex.count_ones(n)}, ") end)


#iex(2)> Enum.each(0..63, fn(n) -> IO.puts(n) end)
