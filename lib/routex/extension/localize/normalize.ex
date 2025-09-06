defmodule Routex.Extension.Localize.Normalize do
  @moduledoc false

  def locale_value(nil, _key), do: nil
  def locale_value(value, :locale), do: value

  # credo:disable-for-next-line
  def locale_value(value, key) when key in [:region, :language] do
    case value do
      <<input::binary-size(2)>> ->
        if(key == :language, do: String.downcase(input), else: String.upcase(input))

      <<input::binary-size(3)>> ->
        if(key == :language, do: String.downcase(input), else: String.upcase(input))

      <<lang::binary-size(2), ?-, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      <<lang::binary-size(3), ?-, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      <<lang::binary-size(2), ?_, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      <<lang::binary-size(3), ?_, rest::binary>> ->
        if(key == :language, do: String.downcase(lang), else: String.upcase(rest))

      _other ->
        nil
    end
  end
end
