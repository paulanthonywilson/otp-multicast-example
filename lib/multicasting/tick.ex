defmodule Multicasting.Tick do
  @moduledoc """
  Kill cord - times out and dies if not called within a timeout period.  Process linking / supervision
  can be used to cause the death of the other processs for a fresh start.
  """
  use GenServer

  @doc """
  Options, GenServer start options (eg name) plus:

  * timeout - the timeout value (milliseconds)

  """
  def start_link(opts) do
    {timeout, opts} = Keyword.pop!(opts, :timeout)
    GenServer.start_link(__MODULE__, timeout, opts)
  end

  def init(timeout) do
    {:ok, %{timeout: timeout}, timeout}
  end

  def tick(server) do
    GenServer.cast(server, :tick)
  end

  def handle_cast(:tick, %{timeout: timeout} = s) do
    {:noreply, s, timeout}
  end

  def handle_info(:timeout, s) do
    {:stop, :normal, s}
  end
end
