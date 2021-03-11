defmodule Multicasting.ExpiringRegistry do
  @moduledoc """
  A key-value registry. The registry entries expire after 35 seconds if they are not
  refreshed / updated.
  """

  use GenServer

  alias Multicasting.ExpiringRegistryEntry

  @doc """
  Create a registry. Options must include a `registry_name`. Other options (eg `name`) are
  passed on the `GenServer.start_link/3`.
  """
  @spec start_link(keyword()) :: :ignore | {:error, any} | {:ok, pid}
  def start_link(opts) do
    {registry_name, opts} = Keyword.pop!(opts, :registry_name)
    GenServer.start_link(__MODULE__, registry_name, opts)
  end

  def init(registry_name) do
    {:ok, %{registry_name: registry_name}}
  end

  @doc """
  Register a key value pair with the registry.
  """
  @spec register(atom | pid, any, any) :: :ok
  def register(server, key, value) do
    GenServer.cast(server, {:register, {key, value}})
  end

  @doc """
  Return a list of key-value pairs (as tuples) that are currently registered
  """
  @spec registrations(atom | pid) :: list({any, any})
  def registrations(server) do
    GenServer.call(server, :registrations)
  end

  def handle_call(:registrations, _from, %{registry_name: registry_name} = state) do
    registrations =
      registry_name
      |> Registry.select([{{:"$1", :_, :"$3"}, [], [{{:"$1", :"$3"}}]}])

    {:reply, registrations, state}
  end

  def handle_cast({:register, {key, value}}, %{registry_name: registry_name} = state) do
    case Registry.lookup(registry_name, key) do
      [{entry_pid, _}] ->
        update_entry(entry_pid, registry_name, key, value)

      [] ->
        new_entry(registry_name, key, value)
    end

    {:noreply, state}
  end

  defp update_entry(entry_pid, registry_name, key, value) do
    :ok = ExpiringRegistryEntry.update(entry_pid, value)
  catch
    :exit, _value ->
      new_entry(registry_name, key, value)
  end

  defp new_entry(registry_name, key, value) do
    {:ok, _pid} =
      DynamicSupervisor.start_child(
        Multicasting.DynamicSupervisor,
        {ExpiringRegistryEntry, {registry_name, key, value}}
      )
  end
end
