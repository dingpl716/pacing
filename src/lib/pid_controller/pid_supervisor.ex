defmodule Pacing.PIDSupervisor do
  use DynamicSupervisor

  alias Pacing.{PIDController, PIDState}

  def start_link(init_arg) do
    DynamicSupervisor.start_link(__MODULE__, init_arg, name: __MODULE__)
  end


  @doc """
  Starts a PID controller.
  """
  def start_child(%PIDState{} = state) do
    DynamicSupervisor.start_child(__MODULE__, {PIDController, state})
  end

  @impl true
  def init(_init_arg) do
    DynamicSupervisor.init(strategy: :one_for_one)
  end
end
