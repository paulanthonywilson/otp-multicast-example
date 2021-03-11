defmodule Multicasting.Application do
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    children = [
      Multicasting.BroadcasterReceiverSupervisor,
      {DynamicSupervisor, strategy: :one_for_one, name: Multicasting.DynamicSupervisor}
    ]

    opts = [strategy: :one_for_one, name: Multicasting.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
