defmodule Phoenix.Plugs.ContentTypeFetcher do
  import Plug.Conn
  alias Phoenix.Mime

  @moduledoc """
  Plug to parse Accept headers for response content-type

  Used by Phoenix.Controller to determine extension of `render/3` template

  Lookup priority
  1. format param of mime extension, ie "html", "json", "xml"
  2. Accept header, ie "text/html,application/xml;q=0.9,*/*;q=0.8"
  3. "text/html" default fallback
  """

  @default_content_type "text/html"

  def init(opts), do: opts

  def call(conn, _), do: fetch(conn)

  @doc """
  Assigns the String response content-type to private :phoenix_content_type
  """
  def fetch(conn) do
    type = conn.params["format"]
    |> Mime.type_from_ext
    |> Kernel.||(primary_accept_format(accept_formats(conn)))
    |> Kernel.||(@default_content_type)

    assign_private(conn, :phoenix_content_type, type)
  end
  defp primary_accept_format(["*/*" | _rest]), do: @default_content_type
  defp primary_accept_format([type | _rest]), do: Mime.valid_type?(type) && type
  defp primary_accept_format(_), do: nil

  @doc """
  Returns the List of String Accept headers, in order of priority
  """
  def accept_formats(conn) do
    conn
    |> get_req_header("accept")
    |> parse_accept_headers
  end
  defp parse_accept_headers([]), do: []
  defp parse_accept_headers([accepts | _rest]) do
    accepts
    |> String.split(",")
    |> Enum.map fn format ->
      String.split(format, ";") |> Enum.at(0)
    end
  end
end
