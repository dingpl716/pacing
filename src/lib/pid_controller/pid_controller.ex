defmodule Pacing.PIDController do
  use GenServer
  require Logger
  alias Pacing.PIDState

  def start_link([{:state, state} | opts]) do
    GenServer.start_link(__MODULE__, state, opts)
  end

  def stop(server) do
    GenServer.stop(server)
  end

  @spec set_target_impression(atom | pid | {atom, any} | {:via, atom, any}, number) :: any
  def set_target_impression(server, target_impression) when is_number(target_impression) do
    GenServer.call(server, {:set_target_impression, target_impression})
  end

  @spec set_end_time(atom | pid | {atom, any} | {:via, atom, any}, number) :: any
  def set_end_time(server, end_time) when is_number(end_time) do
    GenServer.call(server, {:set_end_time, end_time})
  end

  @doc """
  Report an impression has been successfully delivered.
  """
  @spec add_delivered_impression(atom | pid | {atom, any} | {:via, atom, any}) :: number
  def add_delivered_impression(server) do
    GenServer.call(server, :add_delivered_impression)
  end

  @doc """
  Get the current round of output from PID controller.

  ## Parameters

    - tick_seconds: The number of seconds to move state forward after this round. Only
    set this parameter when doing simulation, omit it in production.

  """
  @spec get_output(atom | pid | {atom, any} | {:via, atom, any}, number | nil) :: any
  def get_output(server, tick_seconds \\ nil) do
    GenServer.call(server, {:get_output, tick_seconds})
  end

  @doc """
  Determines whether it should fill an ad request in this round.

  ## Parameters

    - tick_seconds: The number of seconds to move state forward after this round. Only
    set this parameter when doing simulation, omit it in production.

  """
  @spec should_fill?(atom | pid | {atom, any} | {:via, atom, any}, number | nil) :: boolean
  def should_fill?(server, tick_seconds \\ nil) do
    GenServer.call(server, {:should_fill, tick_seconds})
  end

  # ========== Call baks ==========
  def init(%PIDState{} = state) do
    {:ok, state}
  end

  def handle_call({:set_target_impression, target_impression}, _caller, state) do
    {:reply, :ok, %{state | target_impression: target_impression}}
  end

  def handle_call({:set_end_time, end_time}, _caller, state) do
    {:reply, :ok, %{state | end_time: end_time}}
  end

  def handle_call(:add_delivered_impression, _caller, state) do
    delivered_impression = state.delivered_impression + 1
    # datetime = state.current_time |> DateTime.from_unix!() |> DateTime.to_iso8601()
    # actual_velocity = state.delivered_impression / (state.current_time - state.start_time)
    # Logger.info("#{datetime},#{delivered_impression},#{actual_velocity}")
    {:reply, delivered_impression, %{state | delivered_impression: delivered_impression}}
  end

  def handle_call({:get_output, tick_seconds}, _caller, state) do
    {output, new_state} = calculate_output(state, tick_seconds)
    {:reply, output, new_state}
  end

  def handle_call({:should_fill, tick_seconds}, _caller, state) do
    case state.delivered_impression >= state.target_impression do
      true ->
        {:reply, false, state}

      false ->
        actual_velocity = state.delivered_impression / (state.current_time - state.start_time)
        {desired_velocity, new_state} = calculate_output(state, tick_seconds)
        datetime = state.current_time |> DateTime.from_unix!() |> DateTime.to_iso8601()
        Logger.info("#{datetime},#{state.delivered_impression},#{actual_velocity}")

        case desired_velocity >= actual_velocity do
          true -> {:reply, true, new_state}
          false -> {:reply, false, new_state}
        end
    end
  end


  defp calculate_output(%PIDState{} = state, tick_seconds) do
    setpoint = state.target_impression / (state.end_time - state.start_time)
    input = state.delivered_impression / (state.current_time - state.start_time)

    error = setpoint - input
    f_output = state.kf * setpoint
    p_output = state.kp * error
    i_output = state.ki * (state.error_sum + error)
    d_output = state.kd * (input - state.last_input)
    output = f_output + p_output + i_output + d_output

    current_time =
      case tick_seconds do
        nil -> DateTime.utc_now() |> DateTime.to_unix()
        _ -> state.current_time + round(tick_seconds)
      end

    new_state = %{
      state
      | last_input: input,
        error_sum: state.error_sum + error,
        current_time: current_time
    }

    {output, new_state}
  end
end
