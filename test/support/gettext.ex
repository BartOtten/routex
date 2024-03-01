defmodule Routex.Test.Support.Gettext do
  use Gettext,
    otp_app: :example_web,
    priv: "test/support/fixtures/single_messages",
    default_domain: "routes"
end
