defmodule Routex.Extension.Localize do
  @moduledoc """
  Localize your Phoenix with minimal configuration.

  This extension activates `Routex.Extension.Localize.Routes`
  and `Routex.Extension.Localize.Runtime` to provide localization support.

  For configuration options and additional details, refer to their
  documentation.
  """

  alias __MODULE__
  @deps [Localize.Routes, Localize.Runtime]

  def configure(config, _backend) do
    config
    |> Keyword.update(:extensions, @deps, fn existing_extensions ->
      (@deps ++ existing_extensions) |> Enum.uniq()
    end)
  end
end
