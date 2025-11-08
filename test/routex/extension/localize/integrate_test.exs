defmodule RoutexWeb.Gettext do
  def known_locales, do: ["en"]
  def __gettext__(:known_locales), do: ["en", "fr"]
  def __gettext__(:default_locale), do: "en"
end

defmodule Routex.Extension.Localize.IntegrateTest do
  use ExUnit.Case

  import Routex.Extension.Localize.Integrate

  @mix_content """
  defmodule FBar.MixProject do
    use Mix.Project
  end
  """

  @incorrect_mix_content """
  defmodule FBar.Mix do
    use Mix.Project
  end
  """

  test "Base module is extracted from Mixfile content" do
    assert "FBar" == extract_main_module(@mix_content)
  end

  test "Returns nil when not a MixProject module" do
    assert nil == extract_main_module(@incorrect_mix_content)
  end

  test "Auto detect, no backend given" do
    assert {Gettext, RoutexWeb.Gettext, ["en", "fr"], "en"} == auto_detect(nil)
  end

  test "Auto detect, correct backend given" do
    assert {Gettext, RoutexWeb.Gettext, ["en", "fr"], "en"} == auto_detect(RoutexWeb.Gettext)
  end

  test "Auto detect, non-existing backend given" do
    exception = assert_raise ArgumentError, fn -> auto_detect(NonExisting) end

    assert exception.message =~
             "Could not load locale backend: NonExisting"
  end
end
