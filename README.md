# Ansible Role – Pangolin Upgrade

Ce rôle Ansible permet de **mettre à jour Pangolin et son écosystème**
via **Docker Compose**, en appliquant une stratégie simple et assumée :
**arrêt → mise à jour → redémarrage → nettoyage**.

⚠️ Ce rôle implique **un court downtime**.

## Mise à jour 2026-05-09

Le rôle a été mis à jour pour intégrer **CrowdSec Manager** et un site **Newt** dédié, afin d'exposer l'interface CrowdSec Manager via Pangolin et son SSO, sans publier directement le port `8080` sur Internet.

Cette évolution ajoute :

- CrowdSec Manager dans le template Docker Compose ;
- Newt dans le même réseau Docker que CrowdSec Manager ;
- l'injection de `NEWT_ID` et `NEWT_SECRET` depuis les secrets Gitea Actions ;
- la variabilisation des versions CrowdSec et CrowdSec Manager ;
- la suppression de l'exposition publique du port métriques CrowdSec `6060`.

Le chemin attendu devient :

```text
Internet -> Pangolin -> SSO -> Newt -> crowdsec-manager:8080
```


👉 Pour le contexte complet, les choix techniques et le retour d’expérience :
**https://cryptolab.re/posts/2025/pangolin/**

👉 Pour la suite dédiée à CrowdSec Manager :
**https://cryptolab.re/posts/2026/pangolin-crowdsec-manager/**
---

## 🎯 Objectifs

- Arrêter Pangolin proprement
- Mettre à jour les fichiers de configuration (Jinja2)
- Re-pull les images Docker
- Redémarrer Pangolin
- Nettoyer les images Docker inutilisées
- Exposer CrowdSec Manager via Pangolin SSO, sans port public dédié

---

## 📦 Composants gérés

- Pangolin
- Gerbil
- Traefik
- Badger
- CrowdSec
- CrowdSec Traefik Bouncer
- CrowdSec Manager
- Newt

---

## 📁 Structure attendue

```
.
├── README.md
├── playbook-pangolin-upgrade.yml
├── inventory/
│   └── prod.ini
├── vars/
│   └── main.yml
└── roles/
    └── pangolin_upgrade/
        ├── tasks/
        │   └── main.yml
        ├── defaults/
        ├── vars/
        ├── templates/
        │   ├── docker-compose.yml.j2
        │   └── traefik_config.yml.j2
        └── handlers/
```

---

## ▶️ Exécution du playbook

```
ansible-playbook -i inventory/prod.ini playbook-pangolin-upgrade.yml
```

---

## 🧾 Exemple de playbook

```yaml
- hosts: pangolin
  become: true
  vars_files:
    - vars/main.yml
  roles:
    - pangolin_upgrade
```

---

## ⚙️ Variables

Définies dans `vars/main.yml` :

```yaml
gerbil_version: "1.5.0"
pangolin_version: "ee-1.21.1"
traefik_version: "v3.7.11"
badger_version: "v1.6.1"
crowdsec_traefik_version: "v1.7.1"
crowdsec_version: "latest"
crowdsec_manager_version: "latest"
newt_enabled: true
newt_version: "latest"
newt_pangolin_endpoint: "{{ lookup('env', 'NEWT_PANGOLIN_ENDPOINT') }}"
newt_id: "{{ lookup('env', 'NEWT_ID') }}"
newt_secret: "{{ lookup('env', 'NEWT_SECRET') }}"

pangolin_compose_path: "/data/pangolin"
pangolin_traefik_path: "/data/pangolin/config/traefik"
```

---

## 🔐 Variables Gitea Actions

Les secrets Newt ne doivent pas être commités dans Git.

Dans Gitea, configurer une variable :

```text
NEWT_PANGOLIN_ENDPOINT=https://pangolin.example.com
```

Puis deux secrets :

```text
NEWT_ID=...
NEWT_SECRET=...
```

Ces valeurs sont injectées dans le workflow Gitea puis lues par Ansible avec `lookup('env', ...)`.

Le rôle vérifie que ces valeurs existent lorsque `newt_enabled` vaut `true`.

---

## 🌐 Exposition CrowdSec Manager

CrowdSec Manager est exposé uniquement dans le réseau Docker :

```yaml
expose:
  - "8080"
```

Il ne doit pas avoir de mapping public du type :

```yaml
ports:
  - "8080:8080"
```

La ressource Pangolin doit cibler le site Newt correspondant :

```text
Node de sortie : site Newt du serveur CrowdSec Manager
Protocole : http
Host : crowdsec-manager
Port : 8080
Authentification : SSO Pangolin activé
```

Même principe pour les métriques CrowdSec : le port `6060` reste interne au réseau Docker.

---

## 🔄 Déroulement exact du rôle

1. Stop Pangolin  
2. Déploiement des templates Jinja2  
3. Pull des images Docker  
4. Redémarrage de Pangolin  
5. Nettoyage des images Docker inutilisées  

---

## ⚠️ Points d’attention

- Downtime pendant l’exécution
- `docker image prune -af` est agressif
- À utiliser sur un hôte dédié Pangolin

---

## 🔐 Prérequis

- Docker
- Docker Compose v2
- Ansible ≥ 2.14
- Accès SSH root ou sudo

---

## 📜 Licence

MIT
