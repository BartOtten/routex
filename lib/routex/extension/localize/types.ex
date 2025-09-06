defmodule Routex.Extension.Localize.Types do
  @moduledoc """
  Type definitions for locale detection.
  """

  @type locale_key :: :region | :language | :territory | :locale
  @type source :: :accept_language | :body | :cookie | :host | :path | :query | :attrs | :session
  @type locale_result :: %{required(locale_key) => String.t() | nil}

  @type locale_entry :: %{
          language: String.t(),
          region: String.t(),
          territory: String.t(),
          locale: String.t()
        }
end
