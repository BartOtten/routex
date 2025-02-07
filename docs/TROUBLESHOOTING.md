# Troubleshooting

## Where can I find ExampleWeb.Router.RoutexHelpers?
This module does not have a code file. It is generated during compile time
by Routex. You should be able to see a message in the output like the one below:

    Completed: ExampleWeb.RoutexCldrBackend ⇒ Routex.Extension.VerifiedRoutes.create_helpers/3
    Create or update helper module ExampleWeb.Router.RoutexHelpers

Once your project is compiled, you can access it in `iex`.

    iex> exports ExampleWeb.Router.RoutexHelper
    alternatives/1                     attrs/1                            on_mount/4
    sigil_o/2                          sigil_p/2                          url/1
    url/2                              url/3                              url_phx/1

    iex> h ExampleWeb.Router.RoutexHelper.attrs

              def attrs(url)
    Returns Routex attributes of given URL


## Compilation
If you run into compilation issues try these solutions first. If they
do not solve the issue or the issue re-appears, fell free to open an issue.

### Clearing your _build folder
Clearing your build folder might fix issues; especially when the
order of module compilation is the suspect.

`rm -Rf _build && mix compile`

### Debugging
When your application fails to compile you might find the cause by setting the
environment variable `ROUTEX_DEBUG` to `true`.

    ROUTEX_DEBUG=true mix compile

Do note that this might show early compilation issues, but will make the final
compilation fail at all times.

