# credo:disable-for-this-file Credo.Check.Refactor.Apply
# credo:disable-for-this-file Credo.Check.Design.AliasUsage

defmodule Routex.Extension.Localize.Integrate do
  @moduledoc false

  alias Routex.Utils

  @fallback_locale "en"
  @filename "mix.exs"

  @solution """
    \nSet the locale backend to use explicitly in your Routex backend.

    Example:
      locale_backend: ExampleWeb.CustomLocation.Gettext
  """

  # Macro to raise properly
  def auto_detect(locale_backend) do
    cond do
      match?({:module, Cldr}, Code.ensure_compiled(Cldr)) and locale_backend ->
        backend = locale_backend
        fetch_backend!(:cldr, backend)

      match?({:module, Cldr}, Code.ensure_compiled(Cldr)) ->
        fetch_backend!(:cldr, nil)

      match?({:module, Gettext}, Code.ensure_compiled(Gettext)) ->
        backend =
          locale_backend ||
            (lookup_app_module() <> "Web.Gettext") |> String.to_atom()

        fetch_backend!(:gettext, backend)

      match?({:module, Fluent}, Code.ensure_compiled(Fluent)) ->
        backend =
          locale_backend ||
            (lookup_app_module() <> ".Fluent") |> String.to_atom()

        fetch_backend!(:fluent, backend)

      true ->
        {__MODULE__, __MODULE__, [@fallback_locale], @fallback_locale}
    end
  end

  @doc false
  def fetch_backend!(type, backend) do
    case Code.ensure_compiled(backend) do
      {:module, _mod} ->
        do_fetch!(type, backend)

      {:error, _reason} ->
        title = "Could not load locale backend: #{inspect(backend)}"

        Utils.alert(title, @solution)
        raise ArgumentError, title
    end
  end

  defp do_fetch!(:cldr, nil) do
    {Cldr, Cldr, apply(Cldr, :known_locale_names, []), apply(Cldr, :default_locale, [])}
  end

  defp do_fetch!(:cldr, backend) do
    {Cldr, Cldr, apply(Cldr, :known_locale_names, [backend]),
     apply(Cldr, :default_locale, [backend])}
  end

  defp do_fetch!(:gettext, backend) do
    {Gettext, backend, apply(Gettext, :known_locales, [backend]),
     apply(backend, :__gettext__, [:default_locale])}
  end

  defp do_fetch!(:fluent, backend) do
    {Fluent, backend, apply(Fluent, :known_locales, [backend]), "en"}
  end

  # as there is no reliable way to use Project and Config functions, we
  # use Mix-file inspection instead.
  defp lookup_app_module do
    with path when is_binary(path) <- get_mix_path(),
         content when is_binary(content) <- path |> Path.join(@filename) |> File.read!(),
         module when is_binary(module) <- extract_main_module(content) do
      "Elixir." <> module
    else
      false ->
        title = "Could not detect main app module"

        Utils.alert(title, @solution)
        raise ArgumentError, title
    end
  end

  defp get_mix_path do
    Mix.Project.app_path()
    |> Path.split()
    |> Enum.scan("/", &Path.join(&2, &1))
    |> Enum.reverse()
    |> Enum.find(fn
      "/" -> false
      path -> path |> Path.join(@filename) |> File.exists?()
    end)
  rescue
    _error -> false
  end

  @doc false
  def extract_main_module(contents) do
    regex = ~r/defmodule\s*([A-Z][A-Za-z0-9_.]+)\.MixProject do*/

    case Regex.run(regex, contents, capture: :all_but_first) do
      [module_str] -> module_str
      nil -> nil
    end
  end
end
