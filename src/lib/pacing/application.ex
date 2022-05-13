defmodule Pacing.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  alias Pacing.PIDSupervisor

  def start(_type, _args) do
    children = [
      # Starts a worker by calling: Pacing.Worker.start_link(arg)
      # {Pacing.Worker, arg}
      PIDSupervisor
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Pacing.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
