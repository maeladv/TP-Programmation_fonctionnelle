# TP-Programmation_fonctionnelle
## ADVISSE Maël

## Client

### Interaction entre deux clients

![alt text](image.png)
![alt text](image-1.png)

### Robustesse

Si le serveur est déconnecté, on a :

![alt text](image-2.png)
Le serveur redemarre automatiquement

![alt text](image-3.png)
Les clients sont déconnectés mais il n'y a pas de reconnexion automatique. Il ne peuvent donc plus envoyer de messages

Apres avoir implémenté la reconnexion automatique, on a :

![alt text](image-4.png)

Le client est déconnecté puis reconnecté. Toutefois, il doit de nouveau choisir son pseudo

### Robustesse OTP 

La gestion OTP permettrait de redémarrer automatiquement un processus qui plante, au lieu de faire tomber toute l’application. Elle rend aussi le code plus robuste, parce que chaque client, salon ou serveur peut être isolé dans son propre processus supervisé

### Filtrage des messages

![alt text](image-5.png)

Les messages contenant des caratères interdit ne s'envoient pas

### Cryptographie

