defmodule Pacing.PIDState do
  defstruct kp: 0,
            ki: 0,
            kd: 0,
            kf: 0,
            last_input: 0,
            error_sum: 0,
            controller_id: "",
            delivered_impression: 0,
            target_impression: 0,
            start_time: 0,
            end_time: 0,
            current_time: nil
end
