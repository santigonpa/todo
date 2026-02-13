defmodule Todo.DatabaseWorker do
  use GenServer
  @db_folder "./persist"
  def start(folder) do
    {:ok, pid} = GenServer.start(__MODULE__, folder)
    pid
  end

  def store(worker_pid, key, data) do
    GenServer.cast(worker_pid, {:store, key, data})
  end

  def get(worker_pid, key) do
    GenServer.call(worker_pid, {:get, key})
  end

  def init(folder) do
    File.mkdir_p!(@db_folder)
    {:ok, folder}
  end

  def handle_cast({:store, key, data}, state) do
    IO.inspect({:storing, key, data, self()})
    key
    |> file_name()
    |> File.write!(:erlang.term_to_binary(data))

    {:noreply, state}
  end

  def handle_call({:get, key}, _, state) do
    data =
      case File.read(file_name(key)) do
        {:ok, contents} -> :erlang.binary_to_term(contents)
        _ -> nil
      end

    {:reply, data, state}
  end

  defp file_name(key) do
    Path.join(@db_folder, to_string(key))
  end
end
