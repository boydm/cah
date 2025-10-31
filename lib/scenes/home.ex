defmodule Cah.Scene.Home do
  use Scenic.Scene
  require Logger

  alias Scenic.Graph
  alias Scenic.Assets.Stream.Bitmap

  import Scenic.Primitives
  # import Scenic.Components

  # ============================================================================
  # setup

  # --------------------------------------------------------
  def init(scene, _param, _opts) do
    # get the width and height of the viewport. This is to demonstrate creating
    # a transparent full-screen rectangle to catch user input
    {width, height} = scene.viewport.size

    # set up the bitmap stream
    bitmap = Bitmap.build( :g, width, height, clear: :grey )
      |> Bitmap.commit()
    Scenic.Assets.Stream.put( "cah", bitmap )

    graph =
      Graph.build()
      |> rect( {width, height}, fill:  {:stream, "cah"} )

    scene = push_graph(scene, graph)

    {:ok, scene}
  end

  def handle_info( :tick, scene ) do
    Logger.info("tick")
    {:noreply, scene}
  end

  def handle_input(event, _context, scene) do
    Logger.info("Received event: #{inspect(event)}")
    {:noreply, scene}
  end
end
