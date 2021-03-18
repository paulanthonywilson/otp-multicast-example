defmodule Multicasting.BroadcasterReceiverTest do
  use ExUnit.Case
  alias Multicasting.{BroadcasterReceiver, ExpiringRegistry}

  describe "registering incoming hosts" do
    test "other hosts are registered" do
      BroadcasterReceiver.handle_info(
        {:udp, nil, {10, 20, 30, 40}, 49_002, "multitastic:somehost"},
        %{}
      )

      assert :multicast_host_registry
             |> ExpiringRegistry.registrations()
             |> Enum.any?(fn
               {"somehost", {10, 20, 30, 40}} -> true
               _ -> false
             end)
    end

    test "does not register this host as an entry" do
      {:ok, host} = :inet.gethostname()
      host = List.to_string(host)

      BroadcasterReceiver.handle_info(
        {:udp, nil, {10, 20, 30, 50}, 49_002, "multitastic:#{host}"},
        %{}
      )

      refute :multicast_host_registry
             |> ExpiringRegistry.registrations()
             |> Enum.any?(fn
               {^host, _} -> true
               _ -> false
             end)
    end
  end
end
