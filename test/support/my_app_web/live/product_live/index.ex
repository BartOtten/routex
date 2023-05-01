defmodule MyAppWeb.ProductLive.Index do
  use MyAppWeb, :live_view

  @impl true
  def mount(_params, _session, socket) do
    socket = assign(socket, %{products: list_products(), connected: false})

    socket = if connected?(socket), do: assign(socket, :connected, true), else: socket
    {:ok, socket}
  end

  @impl true
  def handle_params(params, _url, socket) do
    {:noreply, apply_action(socket, socket.assigns.live_action, params)}
  end

  defp apply_action(socket, :edit, %{"id" => id}) do
    socket
    |> assign(:page_title, "Edit Product")
    |> assign(:product, get_product!(id))
  end

  defp apply_action(socket, :new, _params) do
    socket
    |> assign(:page_title, "New Product")
    |> assign(:product, %{})
  end

  defp apply_action(socket, :index, _params) do
    socket
    |> assign(:page_title, "Listing Products")
    |> assign(:product, nil)
  end

  @impl true
  def handle_event("delete", %{"id" => id}, socket) do
    _product = get_product!(id)
    {:noreply, assign(socket, :products, list_products())}
  end

  defp list_products do
    []
  end

  defp get_product!(_id) do
    %{}
  end
end
