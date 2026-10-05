# My Infra Lab — DevOps Portfolio Project

[![CI](https://github.com/Petro-bulka/my-infra-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/Petro-bulka/my-infra-lab/actions/workflows/ci.yml)
[![CD](https://github.com/Petro-bulka/my-infra-lab/actions/workflows/cd.yml/badge.svg)](https://github.com/Petro-bulka/my-infra-lab/actions/workflows/cd.yml)

Учебный DevOps-проект: развёртывание веб-приложения (Nginx + PostgreSQL) от Docker Compose до полного CI/CD-пайплайна с self-hosted runner и Kubernetes-кластером.

## 🎯 Цель проекта

Пройти полный путь DevOps-инженера: от контейнеризации приложения до автоматического деплоя в Kubernetes-кластер. Проект демонстрирует навыки работы с Docker, Ansible, CI/CD, мониторингом, Kubernetes, Helm и self-hosted runner.

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                    GitHub Actions (CI/CD)                       │
│         CI: валидация конфигов                                  │
│         CD: сборка образа → ghcr.io → self-hosted runner        │
└─────────────────────────────────────────────────────────────────┘
                                 │
                                 ▼
┌─────────────────────────────────────────────────────────────────┐
│                    K3s Cluster (3 nodes)                        │
│                                                                 │
│   ┌──────────────────┐  ┌──────────────┐  ┌──────────────┐    │
│   │  my-infra-lab    │  │     vm2      │  │  monitoring  │    │
│   │  (control-plane) │  │   (worker)   │  │   (worker)   │    │
│   │                  │  │              │  │              │    │
│   │  Nginx (2 pods)  │  │  Nginx       │  │  Prometheus  │    │
│   │  PostgreSQL      │  │              │  │  Grafana     │    │
│   └──────────────────┘  └──────────────┘  └──────────────┘    │
│                                                                 │
│   Namespace: my-infra-lab                                       │
│   Ingress: nginx-ingress (Traefik)                              │
│   Helm release: my-infra-lab                                    │
└─────────────────────────────────────────────────────────────────┘
```

## 🛠️ Стек технологий

| Категория | Технология | Назначение |
|-----------|-----------|-----------|
| Контейнеризация | Docker, Docker Compose | Упаковка приложения |
| Веб-сервер | Nginx | Отдача статики, reverse proxy |
| База данных | PostgreSQL 15 | Хранение данных |
| IaC | Ansible | Автоматизация развёртывания |
| CI/CD | GitHub Actions | Проверка конфигов + сборка образа |
| CD | Self-hosted runner | Автоматический деплой в K8s |
| Реестр образов | GitHub Container Registry (ghcr.io) | Хранение Docker-образов |
| Мониторинг | Prometheus, Grafana, Node Exporter | Сбор и визуализация метрик |
| Оркестрация | K3s (Kubernetes) | Управление контейнерами в кластере |
| Пакетный менеджер | Helm | Управление релизами в K8s |
| Ingress | Traefik | Маршрутизация трафика |
| ОС | Debian 12 | Хостовая система |

## 💡 Почему именно эти технологии

- **Docker + Compose** — стандарт контейнеризации. Compose позволяет описать multi-container приложение декларативно.
- **Nginx** — самый популярный веб-сервер и reverse proxy.
- **PostgreSQL** — надёжная реляционная БД с открытым исходным кодом.
- **Ansible** — agentless IaC-инструмент. Не требует установки агентов на целевые узлы.
- **GitHub Actions** — встроенный CI/CD в GitHub, не требует внешних серверов.
- **Self-hosted runner** — позволяет GitHub Actions достучаться до K8s-кластера за NAT.
- **ghcr.io** — бесплатный реестр образов, интегрированный с GitHub.
- **Prometheus + Grafana** — индустриальный стандарт мониторинга.
- **K3s** — лёгкая версия Kubernetes. Идеален для учебных и edge-сред.
- **Helm** — пакетный менеджер K8s. Позволяет параметризовать и версионировать приложения.
- **Traefik** — Ingress Controller, встроенный в K3s.

## 📦 Компоненты

### Docker Compose (базовый запуск)

- `nginx` — веб-сервер с HTTPS, отдаёт статику, редиректит HTTP → HTTPS.
- `postgres` — БД с сохранением данных через Docker Volumes.
- Секреты вынесены в `.env` (не коммитятся в Git).

### Ansible (автоматизация)

- `playbook.yml` — установка Docker, клонирование репозитория, генерация SSL-сертификата, запуск стека.
- `roles/docker` — роль для установки Docker на чистую Debian.
- `inventory.ini` — список управляемых узлов (не коммитится).

### CI (GitHub Actions)

При каждом push автоматически проверяется:
- Валидность `docker-compose.yml` (`docker compose config`).
- Синтаксис `nginx.conf` (`nginx -t` внутри контейнера).
- Корректность Ansible playbook (`--syntax-check`).

### CD (GitHub Actions + Self-hosted runner)

При push в `main`:
1. **Собирается** Docker-образ из `Dockerfile`.
2. **Пушится** в ghcr.io с тегами `latest` и `SHA`.
3. **Self-hosted runner** (на VM1) делает `helm upgrade` — K8s подтягивает новый образ.

### Мониторинг VM

- **Node Exporter** — на каждой VM, собирает системные метрики на порту `9100`.
- **Prometheus** — на отдельной VM, забирает метрики каждые 15 секунд.
- **Grafana** — визуализация через дашборд **Node Exporter Full** (ID 1860).

### Kubernetes (K3s)

Кластер из трёх нод: 1 control-plane + 2 worker.

- **Namespace** `my-infra-lab` — изоляция приложения.
- **ConfigMap** `nginx-config` — конфиг Nginx.
- **Secret** `postgres-secret` — пароли PostgreSQL.
- **PVC** `postgres-pvc` — хранилище 2Gi для БД.
- **Deployment** `nginx` — 2 реплики для отказоустойчивости.
- **Deployment** `postgres` — 1 реплика.
- **Service** `nginx` (NodePort) — внешний доступ.
- **Service** `postgres` (headless) — внутренний DNS.
- **Ingress** `nginx-ingress` (Traefik) — маршрутизация по домену.

### Helm

Все K8s-манифесты упакованы в Helm-чарт `my-infra-lab`:

- Параметры в `values.yaml`: реплики, образы, домен, размер PVC.
- Установка: `helm install my-infra-lab ./helm/my-infra-lab -n my-infra-lab --create-namespace`
- Upgrade: `helm upgrade my-infra-lab ./helm/my-infra-lab --set replicaCount=4`
- Rollback: `helm rollback my-infra-lab 1`

### Мониторинг Kubernetes

В кластер установлен **kube-prometheus-stack** через Helm:

- Prometheus — сбор метрик K8s (ноды, поды, API-сервер).
- Grafana — визуализация с дашбордами Kubernetes.
- kube-state-metrics — состояние K8s-объектов.
- Node Exporter — метрики нод.

## 🚀 Быстрый старт

### Вариант 1: Docker Compose (локально)

```bash
git clone https://github.com/Petro-bulka/my-infra-lab.git
cd my-infra-lab
cp .env.example .env
mkdir -p certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/nginx.key -out certs/nginx.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=MyLab/CN=localhost"
docker compose up -d
```

Доступ: `https://<IP_хоста>`

### Вариант 2: Ansible (на чистую Debian)

```bash
cd ansible
cp inventory.ini.example inventory.ini
nano inventory.ini  # укажите IP целевого сервера
ansible-playbook -i inventory.ini playbook.yml
```

### Вариант 3: Kubernetes (K3s + Helm)

```bash
helm install my-infra-lab ./helm/my-infra-lab \
  -n my-infra-lab \
  --create-namespace
```

Доступ: `http://my-infra-lab.local:30875`

### Мониторинг VM

```bash
cd monitoring
cp prometheus.yml.example prometheus.yml
nano prometheus.yml  # укажите IP ваших VM
docker compose up -d
```

- Prometheus: `http://<IP_VM3>:9090`
- Grafana: `http://<IP_VM3>:3000` (admin/admin)

### Мониторинг K8s

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  -f monitoring-k8s/values.yaml \
  -n monitoring --create-namespace
```

- Grafana: `http://<IP_ноды>:32000`

## 📁 Структура репозитория

```
my-infra-lab/
├── .github/workflows/
│   ├── ci.yml                  # CI: валидация конфигов
│   └── cd.yml                  # CD: сборка образа + деплой
├── ansible/                    # Ansible playbook и роли
│   ├── playbook.yml
│   ├── inventory.ini.example
│   └── roles/docker/
├── helm/my-infra-lab/          # Helm-чарт
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── k8s/                        # Kubernetes манифесты (без Helm)
│   ├── namespace.yaml
│   ├── configmap-nginx.yaml
│   ├── secret-postgres.yaml.example
│   ├── pvc-postgres.yaml
│   ├── deployment-nginx.yaml
│   ├── deployment-postgres.yaml
│   ├── service-nginx.yaml
│   ├── service-postgres.yaml
│   └── ingress-nginx.yaml
├── monitoring/                 # Prometheus + Grafana (VM)
│   ├── docker-compose.yml
│   └── prometheus.yml.example
├── monitoring-k8s/             # kube-prometheus-stack
│   └── values.yaml
├── html/                       # Статика для Nginx
│   └── index.html
├── Dockerfile                  # Сборка образа
├── docker-compose.yml          # Базовый запуск
├── nginx.conf                  # Конфиг Nginx
├── .env.example                # Шаблон секретов
└── README.md
```

## ✅ Что реализовано

- [x] Контейнеризация приложения (Nginx + PostgreSQL)
- [x] HTTPS с самоподписанным сертификатом (Docker Compose)
- [x] Хранение секретов через `.env` (не в Git)
- [x] Автоматизация развёртывания через Ansible
- [x] CI через GitHub Actions (валидация конфигов)
- [x] Мониторинг VM через Prometheus + Grafana + Node Exporter
- [x] Развёртывание в K3s-кластере из 3 нод
- [x] Helm-чарт для параметризованного развёртывания
- [x] Ingress (Traefik) для маршрутизации
- [x] Мониторинг K8s через kube-prometheus-stack
- [x] CD: сборка образа в ghcr.io
- [x] CD: автоматический деплой через self-hosted runner
- [x] Self-healing и масштабирование в Kubernetes
- [x] Документация и бейджи CI/CD

## 🎓 Чему я научился

- **Docker:** контейнеризация, multi-container приложения, volumes, сети, секреты.
- **Nginx:** веб-сервер, reverse proxy, HTTPS, редиректы.
- **Ansible:** inventory, playbook, roles, идемпотентность, IaC.
- **CI/CD:** GitHub Actions, workflow, jobs, steps, self-hosted runner, ghcr.io.
- **Мониторинг:** Prometheus, PromQL, Grafana, дашборды, Node Exporter, kube-state-metrics.
- **Kubernetes:** K3s, pods, deployments, services, configmaps, secrets, PVC, Ingress, self-healing, масштабирование.
- **Helm:** чарты, шаблоны, values.yaml, upgrade, rollback.
- **Linux:** Debian, systemd, SSH, сети, диагностика.
- **Отладка:** ImagePullBackOff, PVC immutability, отсутствие volumes, ConfigMap conflicts.

## 🐛 Известные проблемы и решения

- **Геоблокировка registry.k8s.io** — настроен `registries.yaml` для перенаправления на Docker Hub.
- **PVC иммутабельны** — используем `helm upgrade` без `--force` для обновления образа.
- **Helm не обновляет ConfigMap** — при необходимости удаляем ConfigMap вручную и делаем `helm upgrade`.
- **ghcr.io требует lowercase** — используем `${GITHUB_REPOSITORY,,}` в workflow.
