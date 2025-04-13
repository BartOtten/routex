defmodule Routex.Extension.Localize.Phoenix do
  @moduledoc """
  Localize your Phoenix with minimal configuration.

  This extension activates `Routex.Extension.Localize.Phoenix.Routes`
  and `Routex.Extension.Localize.Phoenix.Runtime` to provide localization support.

  For configuration options and additional details, refer to their
  documentation.
  """

  @deps [__MODULE__.Routes, __MODULE__.Runtime]

  def configure(config, _backend) do
    config
    |> Keyword.update(:extensions, @deps, fn existing_extensions ->
      (@deps ++ existing_extensions) |> Enum.uniq()
    end)
  end
end
