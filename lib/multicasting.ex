defmodule Multicasting do
  @moduledoc false

  @doc """
  All our registered friend
  """
  @spec registered_peers :: [{String.t(), :inet.ip4_address()}]
  def registered_peers do
    Multicasting.ExpiringRegistry.registrations(:multicast_host_registry)
  end
end
