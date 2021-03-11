defmodule Multicasting.BroadcasterReceiverSupervisor do
  @moduledoc false
  use Supervisor

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(arg) do
    children = [
      {Multicasting.Tick, [timeout: 35_000, name: :broadcaster_receiver_tick]},
      Multicasting.BroadcasterReceiver
    ]

    Supervisor.init(children, strategy: :one_for_all)
  end
end
