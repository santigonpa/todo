defmodule Todo.Database do
  use GenServer
  @db_folder "./persist"
  def start do
    GenServer.start(__MODULE__, nil, name: __MODULE__)
  end

  def store(key, data) do
    GenServer.cast(__MODULE__, {:store, key, data})
  end

  def get(key) do
    GenServer.call(__MODULE__, {:get, key})
  end

  def choose_worker(key) do
    :erlang.phash2(key, 3)
  end

  def init(_) do
    File.mkdir_p!(@db_folder)

    workers =
      0..2
      |> Enum.map(fn i -> {i, Todo.DatabaseWorker.start(@db_folder)} end)
      |> Enum.into(%{})

    {:ok, workers}
  end

  def handle_cast({:store, key, data}, workers) do
    worker_id = choose_worker(key)
    worker_pid = Map.fetch!(workers, worker_id)

    Todo.DatabaseWorker.store(worker_pid, key, data)

    {:noreply, workers}
  end

  def handle_call({:get, key}, _, workers) do
    worker_id = choose_worker(key)
    worker_pid = Map.fetch!(workers, worker_id)

    data = Todo.DatabaseWorker.get(worker_pid, key)

    {:reply, data, workers}
  end
end
