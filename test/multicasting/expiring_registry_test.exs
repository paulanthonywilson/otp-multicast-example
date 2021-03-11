defmodule Multicasting.ExpiringRegistryTest do
  use ExUnit.Case
  alias Multicasting.{ExpiringRegistry, ExpiringRegistryEntry}

  setup do
    registry_name = String.to_atom("#{inspect(self())}_registry")
    {:ok, _} = Registry.start_link(keys: :unique, name: registry_name)
    {:ok, expiring_registry} = ExpiringRegistry.start_link(registry_name: registry_name)
    {:ok, expiring_registry: expiring_registry, registry_name: registry_name}
  end

  test "registering and retrieving a key and value", %{
    expiring_registry: expiring_registry
  } do
    assert :ok == ExpiringRegistry.register(expiring_registry, "k1", "v1")
    assert [{"k1", "v1"}] == ExpiringRegistry.registrations(expiring_registry)
  end

  test "value for same key is updated", %{expiring_registry: expiring_registry} do
    :ok = ExpiringRegistry.register(expiring_registry, "k1", "v1")
    :ok = ExpiringRegistry.register(expiring_registry, "k1", "v2")
    assert [{"k1", "v2"}] == ExpiringRegistry.registrations(expiring_registry)
  end

  test "values for different keys are added to the registrations", %{
    expiring_registry: expiring_registry
  } do
    :ok = ExpiringRegistry.register(expiring_registry, "k1", "v1")
    :ok = ExpiringRegistry.register(expiring_registry, "k2", "v2")

    assert [{"k1", "v1"}, {"k2", "v2"}] ==
             ExpiringRegistry.registrations(expiring_registry)
  end

  test "values in the expiring_registry expire",
       %{expiring_registry: expiring_registry, registry_name: registry_name} do
    ExpiringRegistry.register(expiring_registry, "k1", "v1")
    :sys.get_state(expiring_registry)
    [{entry_pid, _}] = Registry.lookup(registry_name, "k1")

    send(entry_pid, :timeout)

    assert [] ==
             wait_until_equals(
               [],
               fn -> ExpiringRegistry.registrations(expiring_registry) end
             )
  end

  defp wait_until_equals(expected, actual_fn, attempt_count \\ 0)
  defp wait_until_equals(_expected, actual_fn, 100), do: actual_fn.()

  defp wait_until_equals(expected, actual_fn, attempt_count) do
    case actual_fn.() do
      ^expected ->
        expected

      _ ->
        :timer.sleep(1)
        wait_until_equals(expected, actual_fn, attempt_count + 1)
    end
  end

  test "timeout and update race condition", %{
    expiring_registry: expiring_registry,
    registry_name: registry_name
  } do
    ExpiringRegistry.register(expiring_registry, "k1", "v1")
    :sys.get_state(expiring_registry)
    [{entry_pid, _}] = Registry.lookup(registry_name, "k1")

    send(entry_pid, :timeout)
    ExpiringRegistry.register(expiring_registry, "k1", "v2")
    assert [{"k1", "v2"}] == ExpiringRegistry.registrations(expiring_registry)
  end

  test "timeout is set when creating or updating entries", %{registry_name: registry_name} do
    assert {:ok, _, 35_000} = ExpiringRegistryEntry.init({registry_name, "k1", "v1"})

    assert {:reply, _, _, 35_000} =
             ExpiringRegistryEntry.handle_call({:update, "v1"}, {}, %{
               registry_name: registry_name,
               key: "k1"
             })
  end
end
