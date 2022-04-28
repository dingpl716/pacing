defmodule Mix.Tasks.Pacing.Simulate do
  use Mix.Task
  alias Pacing.{PIDState, PIDController, SimulateUtils}

  def run(_) do
    SimulateUtils.clean_output_file()
    Mix.Task.run("app.start")
    impression_rate = 0.45
    target_impression = 20000
    total_daily_requests = 10000
    days = 14
    now = DateTime.utc_now()
    later = DateTime.add(now, days * 24 * 3600, :second)
    current = DateTime.add(now, 1, :second)

    state = %PIDState{
      kp: 1,
      ki: 1,
      kd: 1,
      kf: 1,
      target_impression: target_impression,
      start_time: DateTime.to_unix(now),
      end_time: DateTime.to_unix(later),
      current_time: DateTime.to_unix(current)
    }

    {:ok, pid_controller} = PIDController.start_link(state: state)

    1..days
    |> Enum.flat_map(fn _ -> SimulateUtils.get_requests_in_a_day(total_daily_requests) end)
    |> Enum.each(fn req_per_hour ->
      SimulateUtils.deliver_an_hour(pid_controller, req_per_hour, impression_rate)
    end)

    PIDController.stop(pid_controller)
  end
end
