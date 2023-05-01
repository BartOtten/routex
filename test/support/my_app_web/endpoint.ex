defmodule MyAppWeb.Endpoint do
  use Phoenix.Endpoint, otp_app: :routex

  def init(:supervisor, config) do
    {:ok,
     config ++
       [
         url: [host: "localhost"],
         render_errors: [view: MyAppWeb.ErrorView, accepts: ~w(html json), layout: false],
         pubsub_server: MyAppWeb.PubSub,
         phoenix_view: [root: "/foo"],
         live_view: [signing_salt: "JCjEQKGP"],
         http: [ip: {127, 0, 0, 1}, port: 4002],
         secret_key_base: "eObH88wUgw/iBZs0vp8PXj3PK7K4mcC3wA3hSAVeZ6Z9RRXKo57Us3G+VscgJCJf",
         server: false
       ]}
  end

  # The session will be stored in the cookie and signed,
  # this means its contents can be read but not tampered with.
  # Set :encryption_salt if you would also like to encrypt it.
  @session_options [
    store: :cookie,
    key: "_example_key",
    signing_salt: "5yQKEMM4"
  ]

  socket("/live", Phoenix.LiveView.Socket, websocket: [connect_info: [session: @session_options]])

  # Serve at "/" the static files from "priv/static" directory.
  #
  # # You should set gzip to true if you are running phx.digest
  # # when deploying your static files in production.
  # plug(Plug.Static,
  #   at: "/",
  #   from: :example,
  #   gzip: false,
  #   only: ~w(assets fonts images favicon.ico robots.txt)
  # )

  # # Code reloading can be explicitly enabled under the
  # # :code_reloader configuration of your endpoint.
  # if code_reloading? do
  #   socket("/phoenix/live_reload/socket", Phoenix.LiveReloader.Socket)
  #   plug(Phoenix.LiveReloader)
  #   plug(Phoenix.CodeReloader)
  #   plug(Phoenix.Ecto.CheckRepoStatus, otp_app: :example)
  # end

  # plug(Phoenix.LiveDashboard.RequestLogger,
  #   param_key: "request_logger",
  #   cookie_key: "request_logger"
  # )

  # plug(Plug.RequestId)
  # plug(Plug.Telemetry, event_prefix: [:phoenix, :endpoint])

  plug(Plug.Parsers,
    parsers: [:urlencoded, :multipart, :json],
    pass: ["*/*"],
    json_decoder: Jason
  )

  plug(Plug.MethodOverride)
  plug(Plug.Head)
  plug(Plug.Session, @session_options)
  plug(MyAppWeb.MultiLangRouter)
end
