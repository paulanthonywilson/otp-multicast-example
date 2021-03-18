defmodule Multicasting.BroadcasterReceiver do
  @moduledoc """
  Broadcasts hostname via multicast on all network interfaces every 15 seconds. Also
  receives broadcasts from self and peers, and logs the result to the console.
  """

  use GenServer

  alias Multicasting.ExpiringRegistry

  require Logger

  @port (case Mix.env() do
           :test -> 49_002
           _ -> 49_001
         end)

  @active 1
  @multicast_group_ip {239, 2, 3, 4}
  @udp_options [
    :binary,
    active: @active,
    add_membership: {@multicast_group_ip, {0, 0, 0, 0}},
    multicast_loop: true,
    multicast_ttl: 1
  ]

  @broadcast_interval 15_000
  @message_prefix "multitastic:"

  @name __MODULE__

  @spec start_link(any) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(_) do
    GenServer.start_link(__MODULE__, {}, name: @name)
  end

  def init(_opts) do
    {:ok, socket} = :gen_udp.open(@port, @udp_options)
    send(self(), :broadcast)
    {:ok, %{socket: socket}}
  end

  def handle_info(:broadcast, %{socket: socket} = state) do
    Process.send_after(self(), :broadcast, @broadcast_interval)

    :ok =
      :gen_udp.send(socket, @multicast_group_ip, @port, "#{@message_prefix}#{this_hostname()}")

    {:noreply, state}
  end

  def handle_info({:udp, _port, ip, _port_number, @message_prefix <> hostname}, state) do
    Multicasting.Tick.tick(:broadcaster_receiver_tick)

    if hostname != this_hostname() do
      ExpiringRegistry.register(:multicast_host_registry, hostname, ip)
    end

    {:noreply, state}
  end

  def handle_info({:udp_passive, _}, %{socket: socket} = state) do
    :inet.setopts(socket, active: @active)
    {:noreply, state}
  end

  def handle_info(msg, state) do
    Logger.debug(fn -> "Unexpected message to #{__MODULE__}: #{inspect(msg)}" end)
    {:noreply, state}
  end

  defp this_hostname do
    {:ok, name} = :inet.gethostname()
    List.to_string(name)
  end
end
