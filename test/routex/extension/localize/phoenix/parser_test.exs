defmodule Routex.Extension.Localize.Phoenix.ParserTest do
  use ExUnit.Case

  alias Routex.Extension.Localize.Phoenix.Parser

  describe "parse_accept_language/1" do
    test "parses accept-language header with multiple locales and qualities" do
      header = "en-US,fr-FR;q=0.8,de;q=0.5"
      result = Parser.parse_accept_language(header)

      assert length(result) == 3
      [en, fr, de] = result

      assert en == %{
               language: "en",
               region: "US",
               territory: "US",
               locale: "en-US",
               quality: 1.0
             }

      assert fr == %{
               language: "fr",
               region: "FR",
               territory: "FR",
               locale: "fr-FR",
               quality: 0.8
             }

      assert de == %{
               language: "de",
               region: nil,
               territory: nil,
               locale: "de",
               quality: 0.5
             }
    end

    test "handles empty header list" do
      assert Parser.parse_accept_language([]) == []
    end

    test "handles list with single any header" do
      result = Parser.parse_accept_language(["*"])
      assert result == []
    end

    test "handles list with single header" do
      result = Parser.parse_accept_language(["en-US;q=0.8"])
      assert length(result) == 1
      assert hd(result).quality == 0.8
    end

    test "ignores invalid quality values" do
      header = "en-US;q=invalid,nl-BE;q=0.9,fr-FR;q=2.0,de;q=-0.5"
      result = Parser.parse_accept_language(header)

      assert length(result) == 1
      assert hd(result).locale == "nl-BE"
      assert hd(result).quality == 0.9
    end

    test "handles whitespace in header" do
      header = " en-US , fr-FR ; q=0.8 "
      result = Parser.parse_accept_language(header)

      assert length(result) == 2
      [en, fr] = result
      assert en.locale == "en-US"
      assert fr.locale == "fr-FR"
      assert fr.quality == 0.8
    end

    test "with language only fallbacks" do
      value = "en-US,en;q=0.9,zh-CN;q=0.8,zh;q=0.7"

      expected = [
        %{language: "en", locale: "en-US", quality: 1.0, territory: "US", region: "US"},
        %{language: "en", locale: "en", quality: 0.9, territory: nil, region: nil},
        %{language: "zh", locale: "zh-CN", quality: 0.8, territory: "CN", region: "CN"},
        %{language: "zh", locale: "zh", quality: 0.7, territory: nil, region: nil}
      ]

      assert expected == Parser.parse_accept_language(value)

      value1 = "*"
      expected1 = []
      assert expected1 == Parser.parse_accept_language(value1)

      value2 = "en"
      expected2 = [%{language: "en", locale: "en", quality: 1.0, territory: nil, region: nil}]
      assert expected2 == Parser.parse_accept_language(value2)

      value3 = "en-US"

      expected3 = [
        %{language: "en", locale: "en-US", quality: 1.0, territory: "US", region: "US"}
      ]

      assert expected3 == Parser.parse_accept_language(value3)
    end
  end

  describe "edge cases and error handling" do
    test "handles malformed accept-language header" do
      header = "en-US;q=0.8;invalid,fr-FR;q="
      result = Parser.parse_accept_language(header)

      assert length(result) == 1
      assert hd(result).locale == "en-US"
      assert hd(result).quality == 0.8
    end

    test "handles multiple quality parameters" do
      header = "en-US;q=0.8;q=0.5"
      result = Parser.parse_accept_language(header)

      assert length(result) == 1
      assert hd(result).locale == "en-US"
      assert hd(result).quality == 0.8
    end

    test "handles quality values at boundaries" do
      header = "en;q=0.0,fr;q=1.0,de;q=0.999"
      result = Parser.parse_accept_language(header)

      assert length(result) == 3
      qualities = Enum.map(result, & &1.quality)
      assert Enum.sort(qualities) == [0.0, 0.999, 1.0]
    end

    test "handles invalid quality values" do
      header = "en;q=1.1,fr;q=-0.1,de;q=invalid"
      result = Parser.parse_accept_language(header)

      assert result == []
    end
  end
end
