defmodule Routex.Extension.Localize.ParserTest do
  use ExUnit.Case, async: true
  alias Routex.Extension.Localize.Parser

  describe "parse_locale/1" do
    test "parses simple language code" do
      result = Parser.parse_locale("en")

      assert result == %{
               language: "en",
               region: nil,
               territory: nil,
               locale: "en"
             }
    end

    test "parses language with region using hyphen" do
      result = Parser.parse_locale("en-US")

      assert result == %{
               language: "en",
               region: "US",
               territory: "US",
               locale: "en-US"
             }
    end

    test "parses language with region using underscore" do
      result = Parser.parse_locale("en_US")

      assert result == %{
               language: "en",
               region: "US",
               territory: "US",
               locale: "en_US"
             }
    end

    test "parses three-letter language code" do
      result = Parser.parse_locale("fra")

      assert result == %{
               language: "fra",
               region: nil,
               territory: nil,
               locale: "fra"
             }
    end

    test "handles empty string" do
      assert Parser.parse_locale("") == nil
    end

    test "handles nil input" do
      assert Parser.parse_locale(nil) == nil
    end

    test "handles invalid format" do
      assert Parser.parse_locale("invalid-format-locale") == nil
    end
  end

  describe "extract_locale_parts/1" do
    test "extracts parts from hyphenated locale" do
      assert Parser.extract_locale_parts("en-US") == {"en", "US"}
    end

    test "extracts parts from underscored locale" do
      assert Parser.extract_locale_parts("en_US") == {"en", "US"}
    end

    test "extracts three-letter language code" do
      assert Parser.extract_locale_parts("fra-FR") == {"fra", "FR"}
    end

    test "handles simple language code" do
      assert Parser.extract_locale_parts("en") == {"en", nil}
    end

    test "handles three-letter language only" do
      assert Parser.extract_locale_parts("fra") == {"fra", nil}
    end
  end

  describe "extract_part/2" do
    test "extracts language from simple code" do
      assert Parser.extract_part("en", :language) == "en"
    end

    test "extracts language from hyphenated locale" do
      assert Parser.extract_part("en-US", :language) == "en"
    end

    test "extracts language from underscored locale" do
      assert Parser.extract_part("en_US", :language) == "en"
    end

    test "extracts three-letter language" do
      assert Parser.extract_part("fra", :language) == "fra"
    end

    test "extracts region from hyphenated locale" do
      assert Parser.extract_part("en-US", :region) == "US"
    end

    test "extracts region from underscored locale" do
      assert Parser.extract_part("en_US", :region) == "US"
    end

    test "handles missing region" do
      assert Parser.extract_part("en", :region) == nil
    end

    test "handles invalid format for language" do
      assert Parser.extract_part("e", :language) == nil
    end

    test "handles invalid format for region" do
      assert Parser.extract_part("en-", :region) == nil
    end
  end
end
