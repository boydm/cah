defmodule Cah.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.Assets.Stream.Bitmap

  import Scenic.Primitives
  # import Scenic.Components

  import IEx

  # ============================================================================
  # setup

  @fs 18

  # --------------------------------------------------------
  def init(scene, _param, _opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {width, height} = scene.viewport.size

    # create the CA
    ca = Cah.Ca.Hex.build( width, height )
      # |> Cah.Ca.Hex.dot( 400, 300, 100 )
      |> Cah.Ca.Hex.put!( 100, 100, 63 )
      |> Cah.Ca.Hex.put!( 101, 100, 63 )
      |> Cah.Ca.Hex.put!( 100, 101, 63 )
      |> Cah.Ca.Hex.put!( 101, 101, 63 )

    # set up the bitmap stream
    # bitmap = Bitmap.build( :g, width, height, clear: :black )
    bitmap = Bitmap.build( :g, width, height, clear: :black )
      |> Cah.Ca.Hex.render( ca )
      |> Bitmap.commit()
    Scenic.Assets.Stream.put( "ca", bitmap )

    g = Graph.build(font_size: @fs)
      |> rect( {width, height}, fill:  {:stream, "ca"} )
      |> text( "#{width}x#{height}", fill: :light_green, t: {10,@fs} )
      |> text( "0", fill: :light_green, t: {10,@fs * 2}, id: :count )

    scene = push_graph(scene, g)
      |> assign(:c, 0)
      |> assign(:ca, ca)
      |> assign(:bitmap, bitmap)
      |> assign(:w, width)
      |> assign(:h, height)
      |> assign(:g, g)


    Process.send(self(), :tick, [])

    {:ok, scene}
  end


  def handle_info( :tick, %{assigns: %{ca: ca, bitmap: bitmap, w: w, h: h, c: c, g: g}} = scene ) do
    ca = Cah.Ca.Hex.step( ca )

    bitmap = Bitmap.mutable(bitmap)
      |> Bitmap.clear( 0 )
      |> Cah.Ca.Hex.render( ca )
      |> Bitmap.commit()
    Scenic.Assets.Stream.put( "ca", bitmap )

    g = Graph.modify(g, :count, &text(&1,inspect(c)))
    scene = push_graph(scene, g)

    Process.send(self(), :tick, [])
    {:noreply, assign(scene, g: g, ca: ca, c: c + 1)}
  end

  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

end
