defmodule MiniDiscord.Client do

  @cle Base.decode16!("0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF0123456789ABCDEF")

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
    connect_with_retry(host, port, 1)
  end

  defp connect_with_retry(host, port, attempt) do
      # TODO : Tenter :gen_tcp.connect avec les bonnes options
      # TODO : Si {:ok, socket} -> handshake(socket) puis lancer les deux loops
      # TODO : Si {:error, reason} ->
      # TODO :   Afficher "Tentative #{attempt} échouée : #{reason}"
      # TODO :   Attendre 2 secondes avec :timer.sleep(2000)
      # TODO :   Rappeler connect_with_retry(host, port, attempt + 1)
      options = [:binary, packet: :line, active: false]

      case :gen_tcp.connect(host, port, options) do
          {:ok, socket} ->
              pseudo = rencontre(socket)

              receiver = Task.async(fn -> receive_loop(socket, host, port) end)
              sender = Task.async(fn -> send_loop(socket, pseudo) end)

              Task.await(receiver, :infinity)
              Task.await(sender, :infinity)

          {:error, reason} ->
          IO.puts("Tentative #{attempt} échouée : #{inspect(reason)}")
          :timer.sleep(2000)
          connect_with_retry(host, port, attempt + 1)
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

      String.trim(pseudo)
  end

  defp receive_loop(socket, host, port) do
      # TODO : Appeler :gen_tcp.recv(socket, 0) — bloquant jusqu'à réception
      # TODO : Si {:ok, msg} -> afficher avec IO.write/1 et rappeler receive_loop
      # TODO : Si {:error, _} -> afficher "Déconnecté" et arrêter

      case :gen_tcp.recv(socket, 0) do
        {:ok, msg} ->
          msg_trim = String.trim(msg)
          case dechiffrer_message(msg_trim) do
            {:error, _} -> IO.write(msg)
            msg_clair -> IO.write(msg_clair)
          end
          receive_loop(socket, host, port)

        {:error, reason} ->
          IO.puts("\nConnexion perdue (#{reason}). Reconnexion...")
          # TODO : Fermer proprement la socket avec :gen_tcp.close/1
          # TODO : Rappeler connect_with_retry(host, port, 1)
          :gen_tcp.close(socket)
          connect_with_retry(host, port, 1)
        end
  end

  defp send_loop(socket, pseudo) do
      # TODO : Lire depuis le clavier avec IO.gets("")
      # TODO : Envoyer au serveur avec :gen_tcp.send/2
      # TODO : Rappeler send_loop(socket)

      case IO.gets("") do
        nil ->
          :ok

        msg ->
          msg_trim = String.trim(msg)

          if String.starts_with?(msg_trim, "/") do
            # Les commandes s'envoient en clair
            :gen_tcp.send(socket, msg_trim <> "\r\n")
          else
            # Les messages utilisateurs sont chiffrés avec le pseudo
            case valider_message(msg) do
              {:ok, msg_valide} ->
                msg_formate = "[#{pseudo}] #{msg_valide}"
                msg_chiffre = chiffrer_message(msg_formate)
                :gen_tcp.send(socket, msg_chiffre <> "\r\n")

              {:error, reason} ->
                IO.puts(reason)
            end
          end

          send_loop(socket, pseudo)
      end
  end

  defp valider_message(msg) do
    msg = String.trim(msg)

    cond do
      msg == "" ->
        {:error, "Message vide"}

      String.length(msg) > 500 ->
        {:error, "Message trop long (max 500 chars)"}

      String.match?(msg, ~r/[\\<>]/) ->
        {:error, "Le Message contient des caractères interdits"}

      true ->
        {:ok, msg <> "\r\n"}
    end
  end

  defp recv_print(socket) do
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    IO.write(msg)
    msg  # return the trimmed message for later use if needed
  end

  defp chiffrer_message(msg) do
    iv = :crypto.strong_rand_bytes(16)
    msg_chiffre = :crypto.crypto_one_time(:aes_256_ctr, @cle, iv, msg, true)
    Base.encode64(iv <> msg_chiffre)
  end

  defp dechiffrer_message(msg_encode) do
    case Base.decode64(msg_encode) do
      {:ok, msg_binaire} when byte_size(msg_binaire) > 16 ->
        <<iv::binary-size(16), msg_chiffre::binary>> = msg_binaire
        :crypto.crypto_one_time(:aes_256_ctr, @cle, iv, msg_chiffre, false)
      _ ->
        {:error, "Impossible de déchiffrer"}
    end
  end

end
