defmodule Multicasting.ExpiringRegistryEntry do
  @moduledoc """
  Process responsible for the lifecyle of an entry in a `Multicasting.ExpiringRegistryEntry`

  The process will timeout and exit if `update/2` is not called every 35 seconds.
  """
  use GenServer, restart: :transient

  @expiry_time 35_000

  def start_link({_registry_name, _key, _value} = args) do
    GenServer.start_link(__MODULE__, args)
  end

  @doc """
  Update the value (or keep the same). Resets the timeout preventing expiry within the
  next 35 seconds.
  """
  @spec update(pid, any) :: :ok
  def update(pid, value) do
    GenServer.call(pid, {:update, value})
  end

  def init({registry_name, key, value}) do
    {:ok, _} = Registry.register(registry_name, key, value)
    {:ok, %{registry_name: registry_name, key: key}, @expiry_time}
  end

  def handle_call({:update, value}, _, %{registry_name: registry_name, key: key} = state) do
    {^value, _} = Registry.update_value(registry_name, key, fn _ -> value end)
    {:reply, :ok, state, @expiry_time}
  end

  def handle_info(:timeout, state) do
    {:stop, :normal, state}
  end
end
