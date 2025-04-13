defmodule Routex.Extension.Localize.NormalizeTest do
  use ExUnit.Case

  alias Routex.Extension.Localize.Normalize

  describe "Normalize locale value" do
    test "handles two-letter codes" do
      assert Normalize.locale_value("en", :language) == "en"
      assert Normalize.locale_value("US", :region) == "US"
    end

    test "handles three-letter codes" do
      assert Normalize.locale_value("eng", :language) == "eng"
      assert Normalize.locale_value("USA", :region) == "USA"
    end

    test "handles hyphenated format" do
      assert Normalize.locale_value("en-US", :language) == "en"
      assert Normalize.locale_value("en-US", :region) == "US"
    end

    test "handles underscore format" do
      assert Normalize.locale_value("pt_BR", :language) == "pt"
      assert Normalize.locale_value("pt_BR", :region) == "BR"
    end

    test "returns nil for invalid formats" do
      assert Normalize.locale_value("invalid", :language) == nil
      assert Normalize.locale_value("", :region) == nil
      assert Normalize.locale_value(nil, :language) == nil
    end

    test "preserves full locale value when key is :locale" do
      assert Normalize.locale_value("en-US", :locale) == "en-US"
      assert Normalize.locale_value("pt_BR", :locale) == "pt_BR"
    end
  end
end
