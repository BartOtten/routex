# Troubleshooting

## Where can I find ExampleWeb.Router.RoutexHelpers?
This module does not have a code file. It is generated during compile time
by Routex. You should see a message in the output like the one below:

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


### Inspect generated code

To understand how Routex expands your routes at compile time, you can configure
it to write a copy of the generated helper modules (the expanded AST) to disk.

Add the following to your configuration:

```elixir
config :routex, helper_mod_dir: "/tmp"
 ```

This will output the generated code into the specified directory.
Inspecting these files is useful when debugging issues such as undefined function errors or unexpected route behavior.


### Set the debugging flag

When your application fails to compile you might find the cause by setting the
environment variable `ROUTEX_DEBUG` to `true`.

    ROUTEX_DEBUG=true mix compile

Do note that this might show early compilation issues, but will make the final
compilation fail at all times.


### Delete the _build folder

Deleting the build folder might fix issues; especially when the
order of module compilation is the suspect.

`rm -Rf _build && mix compile`



