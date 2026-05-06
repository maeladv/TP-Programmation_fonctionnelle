defmodule MiniDiscord.ClientHandler do
  require Logger

  def start(socket) do
    :gen_tcp.send(socket, "Bienvenue sur MiniDiscord!\r\n")
    pseudo = choisir_pseudo(socket)

    :gen_tcp.send(socket, "Salons disponibles : #{salons_dispo()}\r\n")
    :gen_tcp.send(socket, "Rejoins un salon (ex: general) : \r\n")
    {:ok, salon} = :gen_tcp.recv(socket, 0)
    salon = String.trim(salon)

    rejoindre_salon(socket, pseudo, salon)
  end

  defp choisir_pseudo(socket) do
    :gen_tcp.send(socket, "Entre ton pseudo : \r\n")
    {:ok, pseudo} = :gen_tcp.recv(socket, 0)
    pseudo = String.trim(pseudo)

    if pseudo_disponible?(pseudo) do
      reserver_pseudo(pseudo)
      pseudo
    else
      :gen_tcp.send(socket, "Pseudo déjà pris, choisis-en un autre.\r\n")
      choisir_pseudo(socket)
    end
  end

  defp rejoindre_salon(socket, pseudo, salon) do
    case Registry.lookup(MiniDiscord.Registry, salon) do
      [] ->
        DynamicSupervisor.start_child(
          MiniDiscord.SalonSupervisor,
          {MiniDiscord.Salon, salon})
      _ -> :ok
    end

    MiniDiscord.Salon.rejoindre(salon, self())
    MiniDiscord.Salon.broadcast(salon, "📢 #{pseudo} a rejoint ##{salon}\r\n")
    :gen_tcp.send(socket, "Tu es dans ##{salon} — écris tes messages !\r\n")

    loop(socket, pseudo, salon)
  end

  defp loop(socket, pseudo, salon) do
    receive do
      {:message, msg} ->
        :gen_tcp.send(socket, msg)
    after 0 -> :ok
    end

    case :gen_tcp.recv(socket, 0, 100) do
      {:ok, msg} ->
        msg = String.trim(msg)

        if String.starts_with?(msg, "/") do
          # Les commandes restent en clair côté serveur
          gerer_commande(socket, pseudo, salon, msg)
        else
          # Les messages sont chiffrés par le client, on les rebroadcast tel quel
          # sans déchiffrer (le serveur ne voit pas le contenu)
          MiniDiscord.Salon.broadcast(salon, msg <> "\r\n")
          loop(socket, pseudo, salon)
        end

      {:error, :timeout} ->
        loop(socket, pseudo, salon)

      {:error, reason} ->
        Logger.info("Client déconnecté : #{inspect(reason)}")
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
        liberer_pseudo(pseudo)
    end
  end

  defp gerer_commande(socket, pseudo, salon, commande) do
    case String.split(commande, " ", parts: 2) do
  # TODO : "/list" -> envoyer la liste des salons avec MiniDiscord.Salon.lister()
  # TODO : "/join <nom>" -> quitter le salon actuel et rejoindre le nouveau
  # TODO : "/quit" -> déconnecter proprement le client
  # TODO : _ -> envoyer "Commande inconnue"
      ["/list"] ->
        :gen_tcp.send(socket, "Salons : #{Enum.join(MiniDiscord.Salon.lister(), ", ")}\r\n")
        loop(socket, pseudo, salon)

      ["/quit"] ->
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
        liberer_pseudo(pseudo)

      ["/join", nouveau_salon] ->
        MiniDiscord.Salon.broadcast(salon, "👋 #{pseudo} a quitté ##{salon}\r\n")
        MiniDiscord.Salon.quitter(salon, self())
        rejoindre_salon(socket, pseudo, String.trim(nouveau_salon))

      _ ->
        :gen_tcp.send(socket, "Commande inconnue\r\n")
        loop(socket, pseudo, salon)
    end
  end

  defp salons_dispo do
    case MiniDiscord.Salon.lister() do
      [] -> "aucun (tu seras le premier !)"
      salons -> Enum.join(salons, ", ")
    end
  end

  # Dans client_handler.ex :
  defp pseudo_disponible?(pseudo) do
  # TODO : Vérifier avec :ets.lookup(:pseudos, pseudo) si le pseudo est déjà pris
  # TODO : Retourner true si disponible, false sinon
    :ets.lookup(:pseudos, pseudo) == []
  end

  defp reserver_pseudo(pseudo) do
  # TODO : Insérer dans :ets avec :ets.insert(:pseudos, {pseudo, self()})
    :ets.insert(:pseudos, {pseudo, self()})
    :ok
  end

  defp liberer_pseudo(pseudo) do
  # TODO : Supprimer de :ets avec :ets.delete(:pseudos, pseudo)
    :ets.delete(:pseudos, pseudo)
    :ok
  end
end
