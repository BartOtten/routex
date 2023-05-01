defmodule MyAppWeb.ProductLive.FormComponent do
  use MyAppWeb, :live_component

  @impl true
  def update(%{product: _product} = assigns, socket) do
    {:ok,
     socket
     |> assign(assigns)}
  end

  @impl true
  def handle_event("validate", %{"product" => _product_params}, socket) do
    _changeset =
      socket.assigns.product
      |> Map.put(:action, :validate)

    {:noreply, socket}
  end

  def handle_event("save", %{"product" => product_params}, socket) do
    save_product(socket, socket.assigns.action, product_params)
  end

  defp save_product(socket, :edit, _product_params) do
    {:noreply,
     socket
     |> push_redirect(to: socket.assigns.return_to)}
  end

  defp save_product(socket, :new, _product_params) do
    {:noreply,
     socket
     |> push_redirect(to: socket.assigns.return_to)}
  end
end
