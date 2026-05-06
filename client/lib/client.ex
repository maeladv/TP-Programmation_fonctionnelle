defmodule MiniDiscord.Client do

  @doc """
  Point d'entrée principal du client.
  host : nom type 'xxxbore.pub'
  port : entier ex: 4040
  """
  def start(host, port) do
    # TODO : Connecter la socket avec :gen_tcp.connect/3
    # TODO : Options : [:binary, packet: :line, active: false]
    # TODO : En cas d'erreur {:error, reason} -> afficher l'erreur et quitter
    # TODO : Appeler la fonction rencontre(socket) pour le pseudo et le salon
    # TODO : Lancer le receiver dans un Task.async : fn -> receive_loop(socket) end
    # TODO : Lancer le sender dans un Task.async : fn -> send_loop(socket) end
    # TODO : Attendre les deux tasks avec Task.await/2 (timeout: :infinity)
      options = [:binary, packet: :line, active: false]

      case :gen_tcp.connect(host, port, options) do
          {:ok, socket} ->
              rencontre(socket)

              receiver = Task.async(fn -> receive_loop(socket) end)
              sender = Task.async(fn -> send_loop(socket) end)

              Task.await(receiver, :infinity)
              Task.await(sender, :infinity)

          {:error, reason} ->
              IO.puts("Erreur de connexion: #{inspect(reason)}")
              {:error, reason}
      end
  end

  defp rencontre(socket) do
      # TODO : Lire les messages du serveur avec recv_print(socket)
      # TODO : Envoyer le pseudo choisi par l'utilisateur avec IO.gets/1
      # TODO : Lire la suite (liste des salons)
      # TODO : Envoyer le nom du salon
      # TODO : Lire la confirmation

      # Acceuil
      recv_print(socket)

      # Psuedo
      recv_print(socket)
      pseudo = IO.gets("")
      :gen_tcp.send(socket, pseudo)

      # Salons (liste)
      recv_print(socket)

      # Salons (choix)
      recv_print(socket)
      salon = IO.gets("")
      :gen_tcp.send(socket, salon)

      recv_print(socket)
  end

  defp receive_loop(socket) do
      # TODO : Appeler :gen_tcp.recv(socket, 0) — bloquant jusqu'à réception
      # TODO : Si {:ok, msg} -> afficher avec IO.write/1 et rappeler receive_loop
      # TODO : Si {:error, _} -> afficher "Déconnecté" et arrêter

      case :gen_tcp.recv(socket, 0) do
        {:ok, msg} ->
          IO.write(msg)
          receive_loop(socket)

        {:error, _} ->
          IO.write("Déconecté")
        end
  end

  defp send_loop(socket) do
      # TODO : Lire depuis le clavier avec IO.gets("")
      # TODO : Envoyer au serveur avec :gen_tcp.send/2
      # TODO : Rappeler send_loop(socket)

      msg = IO.gets("")
      :gen_tcp.send(socket, msg)
      send_loop(socket)
  end

  defp recv_print(socket) do
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    IO.write(msg)
    msg  # return the trimmed message for later use if needed
  end

end
