defmodule Routex.Extension.SimpleLocale.RegistryTest do
  use ExUnit.Case, async: true
  alias Routex.Extension.SimpleLocale.Registry

  describe "language/2" do
    test "returns language info for valid 2-letter code" do
      assert Registry.language("en") == %{
               descriptions: ["English"],
               type: :language
             }
    end

    test "returns default value for invalid language code" do
      default = %{type: "invalid"}
      assert Registry.language("xx", default) == default
    end

    test "returns nil for invalid language code without default" do
      assert Registry.language("xx") == nil
    end

    test "handles nil input" do
      assert_raise(RuntimeError, fn -> Registry.language(nil) end)
      assert Registry.language(nil, :default) == :default
    end

    test "handles empty string" do
      assert Registry.language("") == nil
      assert Registry.language("", :default) == :default
    end

    test "handles case sensitivity" do
      assert Registry.language("EN") == Registry.language("en")
      assert Registry.language("Fra") == Registry.language("fra")
    end
  end

  describe "language?/1" do
    test "returns true for valid 2-letter codes" do
      assert Registry.language?("en")
      assert Registry.language?("fr")
      assert Registry.language?("de")
    end

    test "returns false for invalid codes" do
      refute Registry.language?("xx")
      refute Registry.language?("123")
      refute Registry.language?("invalid")
    end

    test "returns false for nil" do
      refute Registry.language?(nil)
    end

    test "returns false for empty string" do
      refute Registry.language?("")
    end

    test "handles case sensitivity" do
      assert Registry.language?("EN") == Registry.language?("en")
      assert Registry.language?("Fra") == Registry.language?("fra")
    end
  end

  describe "region/2" do
    test "returns region info for valid code" do
      assert Registry.region("US") == %{type: :region, descriptions: ["United States"]}
    end

    test "returns default value for invalid region code" do
      default = %{type: "invalid"}
      assert Registry.region("XX", default) == default
    end

    test "returns nil for invalid region code without default" do
      assert Registry.region("XX") == nil
    end

    test "handles nil input" do
      assert_raise(RuntimeError, fn -> Registry.region(nil) == nil end)
      assert Registry.region(nil, :default) == :default
    end

    test "handles empty string" do
      assert Registry.region("") == nil
      assert Registry.region("", :default) == :default
    end

    test "handles case sensitivity" do
      assert Registry.region("US") == Registry.region("us")
      assert Registry.region("GB") == Registry.region("gb")
    end
  end

  describe "region?/1" do
    test "returns true for valid region codes" do
      assert Registry.region?("US")
      assert Registry.region?("GB")
      assert Registry.region?("FR")
    end

    test "returns false for invalid codes" do
      refute Registry.region?("XX")
      refute Registry.region?("123")
      refute Registry.region?("invalid")
    end

    test "returns false for nil" do
      refute Registry.region?(nil)
    end

    test "returns false for empty string" do
      refute Registry.region?("")
    end

    test "handles case sensitivity" do
      assert Registry.region?("US") == Registry.region?("us")
      assert Registry.region?("GB") == Registry.region?("gb")
    end
  end

  describe "common locale combinations" do
    test "validates common language-region pairs" do
      # Test some common combinations
      combinations = [
        {"en", "US"},
        {"en", "GB"},
        {"fr", "FR"},
        {"de", "DE"},
        {"es", "ES"},
        {"pt", "BR"},
        {"zh", "CN"},
        {"ja", "JP"}
      ]

      Enum.each(combinations, fn {lang, region} ->
        assert Registry.language?(lang), "Language #{lang} should be valid"
        assert Registry.region?(region), "Region #{region} should be valid"
      end)
    end

    # test "validates three-letter codes with regions" do
    #   combinations = [
    #     {"eng", "US"},
    #     {"fra", "FR"},
    #     {"deu", "DE"},
    #     {"spa", "ES"},
    #     {"por", "BR"},
    #     {"zho", "CN"},
    #     {"jpn", "JP"}
    #   ]

    #   Enum.each(combinations, fn {lang, region} ->
    #     assert Registry.language?(lang), "Language #{lang} should be valid"
    #     assert Registry.region?(region), "Region #{region} should be valid"
    #   end)
    # end
  end

  describe "error cases" do
    test "handles invalid input types" do
      # Test with various invalid input types
      invalid_inputs = [
        0,
        1.5,
        %{},
        [],
        true,
        :atom
      ]

      Enum.each(invalid_inputs, fn input ->
        refute Registry.language?(input)
        refute Registry.region?(input)
        assert Registry.language(input) == nil
        assert Registry.region(input) == nil
      end)
    end

    test "handles malformed language codes" do
      malformed = [
        # Too short language
        "e",
        # Too long language
        "engl",
        # Incomplete
        "en-",
        # Incomplete
        "-US",
        # Incomplete
        "en_",
        # Incomplete
        "_US"
      ]

      Enum.each(malformed, fn code ->
        refute Registry.language?(code)
      end)
    end

    test "handles malformed region codes" do
      malformed = [
        # Too short region
        "U",
        # Too long region
        "NSA",
        # Incomplete
        "en-",
        # Incomplete
        "-US",
        # Incomplete
        "en_",
        # Incomplete
        "_US"
      ]

      Enum.each(malformed, fn code ->
        refute Registry.region?(code)
      end)
    end
  end
end
