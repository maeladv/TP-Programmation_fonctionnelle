defmodule MiniDiscord.Salon do
  use GenServer

  def start_link(name) do
    GenServer.start_link(__MODULE__, %{name: name, clients: [], historique: []},
      name: via(name))
  end

  def rejoindre(salon, pid), do: GenServer.call(via(salon), {:rejoindre, pid})
  def quitter(salon, pid),   do: GenServer.call(via(salon), {:quitter, pid})
  def broadcast(salon, msg), do: GenServer.cast(via(salon), {:broadcast, msg})
  def lister do
# TODO : Utiliser Registry.select/2 pour récupérer toutes les clés du Registry
# TODO : Retourner la liste des noms de salons
    Registry.select(MiniDiscord.Registry, [{{:"$1", :_, :_}, [], [:"$1"]}])
  |> Enum.map(&to_string/1)
  end

  def init(state), do: {:ok, state}

  def handle_call({:rejoindre, pid}, _from, state) do
# TODO : Monitorer le pid avec Process.monitor/1
# TODO : Retourner {:reply, :ok, nouvel_état} avec pid ajouté à state.clients

# Amelioration
# TODO : Envoyer l'historique au nouveau client dans handle_call({:rejoindre, pid})
    Process.monitor(pid)
    nouvel_etat = %{state | clients: [pid | state.clients]}
    Enum.each(state.historique, fn msg ->
      send(pid, {:message, msg})
    end)
    {:reply, :ok, nouvel_etat}
  end

  def handle_call({:quitter, pid}, _from, state) do
# TODO : Retourner {:reply, :ok, nouvel_état} avec pid retiré de state.clients
    nouvel_etat = %{state | clients: List.delete(state.clients, pid)}
    {:reply, :ok, nouvel_etat}
  end

  def handle_cast({:broadcast, msg}, state) do
# TODO : Envoyer {:message, msg} à chaque pid dans state.clients
# TODO : Retourner {:noreply, state}

# Amelioration
# TODO : Ajouter msg à state.historique (garder max 10 messages avec Enum.take/2)
    Enum.each(state.clients, fn client_pid ->
      send(client_pid, {:message, msg})
    end)

    nouvel_etat = %{state | historique: Enum.take(state.historique ++ [msg], -10)}
    {:noreply, nouvel_etat}
  end

  def handle_info({:DOWN, _ref, :process, pid, _reason}, state) do
# TODO : Retirer pid de state.clients (il s'est déconnecté)
# TODO : Retourner {:noreply, nouvel_état}
    nouvel_etat = %{state | clients: List.delete(state.clients, pid)}
    {:noreply, nouvel_etat}
  end

  defp via(name), do: {:via, Registry, {MiniDiscord.Registry, name}}
end
