# Ansible Role – Pangolin Upgrade

Ce rôle Ansible permet de **mettre à jour Pangolin et son écosystème**
via **Docker Compose**, en appliquant une stratégie simple :
**mise à jour des fichiers → pull des images → application de la stack → nettoyage**.

⚠️ Ce rôle implique **un court downtime**.


👉 Pour le contexte complet, les choix techniques et le retour d’expérience :
**https://cryptolab.re/posts/2025/pangolin/**
---

## 🎯 Objectifs

- Mettre à jour les fichiers de configuration (Jinja2)
- Re-pull les images Docker
- Appliquer la stack avec Docker Compose
- Nettoyer les images Docker inutilisées

---

## 📦 Composants gérés

- Pangolin
- Gerbil
- Traefik
- Badger
- CrowdSec Traefik Bouncer

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
gerbil_version: "1.3.0"
pangolin_version: "ee-1.14.1"
traefik_version: "v3.6.5"
badger_version: "v1.3.1"
crowdsec_traefik_version: "v1.4.6"

pangolin_compose_path: "/data/pangolin"
pangolin_traefik_path: "/data/pangolin/config/traefik"
```

---

## 🔄 Déroulement exact du rôle

1. Déploiement des templates Jinja2  
2. Pull des images Docker  
3. Application de la stack avec `docker compose up -d --remove-orphans`  
4. Nettoyage des images Docker inutilisées  

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
