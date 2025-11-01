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

  # --------------------------------------------------------
  def init(scene, _param, _opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {width, height} = scene.viewport.size
    # {width, height} = {4,4}

    # create the CA
    ca = Cah.Ca.Hex.build( width, height )
    ca = Cah.Ca.Hex.put!(ca, 2, 2, 1)

    # set up the bitmap stream
    bitmap = Bitmap.build( :g, width, height, clear: :black )
    bitmap = Bitmap.build( :g, width, height, clear: :black )
      |> Cah.Ca.Hex.render( ca )
      |> Bitmap.commit()
    Scenic.Assets.Stream.put( "ca", bitmap )

    graph =
      Graph.build()
      |> rect( {width, height}, fill:  {:stream, "ca"} )

    scene = push_graph(scene, graph)
      |> assign(:ca, ca)
      |> assign(:bitmap, bitmap)
      |> assign(:w, width)
      |> assign(:h, height)

    Process.send(self(), :tick, [])

    {:ok, scene}
  end


  def handle_info( :tick, %{assigns: %{ca: ca, bitmap: bitmap, w: w, h: h}} = scene ) do
    ca = Cah.Ca.Hex.step( ca )

    bitmap = Bitmap.mutable(bitmap)
      |> Bitmap.clear( 0 )
      |> Cah.Ca.Hex.render( ca )
      |> Bitmap.commit()
    Scenic.Assets.Stream.put( "ca", bitmap )

    Process.send(self(), :tick, [])
    {:noreply, assign(scene, :ca, ca)}
  end

  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end

end
