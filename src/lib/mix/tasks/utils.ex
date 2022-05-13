defmodule Pacing.SimulateUtils do
  alias Pacing.PIDController

  @output_folder "./simulate/data"
  @output_file "output.csv"
  @output_path Path.join(@output_folder, @output_file)

  def clean_output_file do
    if File.exists?(@output_path) do
      File.rm!(@output_path)
    end

    {:ok, file} = File.open(@output_path, [:write])
    IO.puts(file, "datetime,delivered_impression,actual_velocity")
    File.close(file)
  end

  def deliver_an_hour(pid_controller, request_per_hour, impression_rate) do
    tick = 3600 / request_per_hour

    1..request_per_hour
    |> Enum.each(fn _ ->
      deliver_a_request(pid_controller, tick, impression_rate)
    end)
  end

  def deliver_a_request(pid_controller, tick, impression_rate) do
    if PIDController.should_fill?(pid_controller, tick) do
      reply_impression(pid_controller, impression_rate)
    end
  end

  def reply_impression(pid_controller, impression_rate) do
    if :rand.uniform() <= impression_rate do
      Task.async(fn ->
        # Process.sleep(:random.uniform(5000))
        PIDController.add_delivered_impression(pid_controller)
      end)
    end
  end

  def get_requests_in_a_day(total_request_daily) do
    template = Application.get_env(:pacing, :request_per_hour_template)
    template_total = Enum.sum(template)
    request_daily = randomize(total_request_daily)

    template
    |> Enum.map(fn req_per_hour ->
      req_per_hour * request_daily / template_total
    end)
    |> Enum.map(&randomize/1)
  end

  defp randomize(value) do
    diff = Enum.random(-10..10) / 100
    trunc(value * (1 + diff))
  end
end
