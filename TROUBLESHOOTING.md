# Troubleshooting

## Compilation

When your application fails to compile you might find the cause by setting the
environment variable `ROUTEX_DEBUG` to `true`.

    ROUTEX_DEBUG=true mix compile

Do note that this might show early compilation issues, but will make the final
compilation fail at all times.
