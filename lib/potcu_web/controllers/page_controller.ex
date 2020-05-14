defmodule PotcuWeb.PageController do
  use PotcuWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
