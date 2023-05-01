defmodule MyAppWeb.ProductLive.Show do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    {:ok, socket}
  end

  @impl true
  def handle_params(%{"id" => id}, _, socket) do
    {:noreply,
     socket
     |> assign(:page_title, page_title(socket.assigns.live_action))
     |> assign(:product, get_product!(id))}
  end

  defp page_title(:show), do: "Show Product"
  defp page_title(:edit), do: "Edit Product"

  defp get_product!(_id) do
    %{}
  end
end
