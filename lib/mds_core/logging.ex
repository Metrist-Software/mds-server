defmodule MdsCore.Logging do
  @moduledoc """
  Deployments log to multiple sinks at once, one of them
  being the database. This stuff is mostly temporary, hopefully
  we can have a somewhat stable API on top of an ever-improving
  implementation
  """

  use GenServer

  @flush_interval_ms 5 * 1_000

  defmodule State do
    defstruct [:output_pid, :deployment_id, :buffer]
  end

  def start_link(output_pid, deployment_id) do
    GenServer.start_link(__MODULE__, [output_pid, deployment_id])
  end

  def error(pid, msg, error \\ nil) do
    GenServer.cast(pid, {:error, msg, make_timestamp(), error})
  end

  def info(pid, msg) do
    GenServer.cast(pid, {:info, msg, make_timestamp()})
  end

  @doc """
  Make a collectable that things like `System.cmd/3` can send data into.
  """
  def stream(pid) do
    IO.stream(pid, :line)
  end

  # == Server side ==

  @impl true
  def init([output_pid, deployment_id]) do
    state = %State{
      output_pid: output_pid,
      deployment_id: deployment_id,
      buffer: []
    }

    Process.flag(:trap_exit, true)
    schedule_flush()
    {:ok, state}
  end

  @impl true
  def handle_cast({:error, msg, date, error}, state) do
    send(state.output_pid, {:error, msg, error})
    state = %State{state | buffer: [MdsData.Deployments.Deployment.Log.error(msg, error, date) | state.buffer]}
    {:noreply, state}
  end

  def handle_cast({:info, msg, date}, state) do
    send(state.output_pid, {:info, msg})
    state = %State{state | buffer: [MdsData.Deployments.Deployment.Log.info(msg, date) | state.buffer]}
    {:noreply, state}
  end

  @impl true
  def handle_info(:flush, state) do
    state =
      if Enum.count(state.buffer) > 0 do
        IO.puts("Sending #{Enum.count(state.buffer)} lines to database.\n")
        MdsData.Deployments.add_to_log(state.deployment_id, Enum.reverse(state.buffer))
        %State{state | buffer: []}
      else
        state
      end

    schedule_flush()
    {:noreply, state}
  end

  # This implements the I/O protocol, see https://www.erlang.org/doc/apps/stdlib/io_protocol.html
  # Makes `IO.stream(log_pid)` and similar things work.
  def handle_info({:io_request, from, reply_as, {:put_chars, :unicode, message}}, state) do
    {_, state} = handle_cast({:info, message, make_timestamp()}, state)
    send(from, {:io_reply, reply_as, :ok})
    {:noreply, state}
  end

  @impl true
  def terminate(_reason, state) do
    handle_info(:flush, state)
  end

  defp schedule_flush, do: Process.send_after(self(), :flush, @flush_interval_ms)

  defp make_timestamp, do: NaiveDateTime.utc_now()
end
