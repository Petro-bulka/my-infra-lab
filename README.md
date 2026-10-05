# My Infra Lab — DevOps Portfolio Project

[![CI](https://github.com/Petro-bulka/my-infra-lab/actions/workflows/ci.yml/badge.svg)](https://github.com/Petro-bulka/my-infra-lab/actions/workflows/ci.yml)

Учебный DevOps-проект: развёртывание веб-приложения (Nginx + PostgreSQL) от локального Docker Compose до Kubernetes-кластера, с автоматизацией через Ansible, CI через GitHub Actions и мониторингом на Prometheus + Grafana.

## 🎯 Цель проекта

Пройти полный путь DevOps-инженера: от контейнеризации приложения до его оркестрации в Kubernetes-кластере. Проект демонстрирует навыки работы с Docker, Ansible, CI/CD, мониторингом и Kubernetes.

## 🏗️ Архитектура

```
┌─────────────────────────────────────────────────────────────────┐
│                         GitHub Actions (CI)                     │
│         Валидация docker-compose, nginx.conf, Ansible            │
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
│   Service: nginx (NodePort 30080)                               │
└─────────────────────────────────────────────────────────────────┘
```

## 🛠️ Стек технологий

| Категория | Технология | Назначение |
|-----------|-----------|-----------|
| Контейнеризация | Docker, Docker Compose | Упаковка приложения |
| Веб-сервер | Nginx | Отдача статики, reverse proxy |
| База данных | PostgreSQL 15 | Хранение данных |
| IaC | Ansible | Автоматизация развёртывания |
| CI | GitHub Actions | Проверка конфигов при push |
| Мониторинг | Prometheus, Grafana, Node Exporter | Сбор и визуализация метрик |
| Оркестрация | K3s (Kubernetes) | Управление контейнерами в кластере |
| ОС | Debian 13 | Хостовая система |

## 💡 Почему именно эти технологии

- **Docker + Compose** — стандарт контейнеризации. Compose позволяет описать multi-container приложение декларативно.
- **Nginx** — самый популярный веб-сервер и reverse proxy, используется в 90% продакшенов.
- **PostgreSQL** — надёжная реляционная БД с открытым исходным кодом.
- **Ansible** — agentless IaC-инструмент. Не требует установки агентов на целевые узлы, работает по SSH.
- **GitHub Actions** — встроенный CI/CD в GitHub, не требует внешних серверов.
- **Prometheus + Grafana** — индустриальный стандарт мониторинга. Pull-модель сбора метрик, мощная визуализация.
- **K3s** — лёгкая версия Kubernetes. Идеален для учебных и edge-сред, полностью совместим с K8s API.
- **Debian** — стабильный дистрибутив Linux, стандарт для серверов.

## 📦 Компоненты

### Docker Compose (базовый запуск)

- `nginx` — веб-сервер с HTTPS, отдаёт статику, редиректит HTTP → HTTPS.
- `postgres` — БД с сохранением данных через Docker Volumes.
- Секреты вынесены в `.env` (не коммитятся в Git).

### Ansible (автоматизация)

- `playbook.yml` — установка Docker, клонирование репозитория, генерация SSL-сертификата, запуск стека.
- `roles/docker` — роль для установки Docker на чистую Debian.
- `inventory.ini` — список управляемых узлов (не коммитится).

### CI (Continuous Integration )

При каждом push автоматически проверяется:
- Валидность `docker-compose.yml` (`docker compose config`).
- Синтаксис `nginx.conf` (`nginx -t` внутри контейнера).
- Корректность Ansible playbook (`--syntax-check`).

## 🚀 CD (Continuous Deployment)

При push в `main` GitHub Actions:
1. Собирает Docker-образ из `Dockerfile`.
2. Пушит его в GitHub Container Registry (ghcr.io).
3. Self-hosted runner делает `git pull` + `helm upgrade`.
4. K8s автоматически пересоздаёт поды (rolling update).

**Триггеры:** `html/**`, `nginx.conf`, `Dockerfile`, `helm/**`.

**Никаких ручных действий** — всё автоматически.

### Workflow

- `.github/workflows/cd.yml` — сборка и push образа.

### Образ

https://ghcr.io/petro-bulka/my-infra-lab:latest

### Мониторинг

- **Node Exporter** — на каждой VM, собирает системные метрики (CPU, RAM, диск, сеть) на порту `9100`.
- **Prometheus** — на отдельной VM, забирает метрики каждые 15 секунд.
- **Grafana** — визуализация через дашборд **Node Exporter Full** (ID 1860).

### Kubernetes (K3s)

Кластер из трёх нод: 1 control-plane + 2 worker.

- **Namespace** `my-infra-lab` — изоляция приложения.
- **ConfigMap** `nginx-config` — конфиг Nginx и `index.html`.
- **Secret** `postgres-secret` — пароли PostgreSQL.
- **PVC** `postgres-pvc` — хранилище 2Gi для БД.
- **Deployment** `nginx` — 2 реплики для отказоустойчивости.
- **Deployment** `postgres` — 1 реплика.
- **Service** `nginx` (NodePort 30080) — внешний доступ.
- **Service** `postgres` (headless) — внутренний DNS.

### Ingress

Приложение доступно через Ingress (Traefik) по домену `my-infra-lab.local`:

```bash
kubectl apply -f k8s/ingress-nginx.yaml
```
## ⎈ Helm

Приложение упаковано в Helm-чарт для параметризованного развёртывания.

### Установка

```bash
helm install my-infra-lab ./helm/my-infra-lab \
  --namespace my-infra-lab \
  --create-namespace
```
## ☸️ Мониторинг Kubernetes

В кластер установлен **kube-prometheus-stack** через Helm:

- Prometheus — сбор метрик K8s (ноды, поды, API-сервер)
- Grafana — визуализация с дашбордами Kubernetes
- kube-state-metrics — состояние K8s-объектов
- Node Exporter — метрики нод

### Установка

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install monitoring prometheus-community/kube-prometheus-stack \
  -f monitoring-k8s/values.yaml \
  -n monitoring --create-namespace
```

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

### Вариант 3: Kubernetes (K3s)

```bash
kubectl apply -f k8s/
```

Доступ: `http://<IP_любой_ноды>:30080`

### Мониторинг

```bash
cd monitoring
cp prometheus.yml.example prometheus.yml
nano prometheus.yml  # укажите IP ваших VM
docker compose up -d
```

- Prometheus: `http://<IP_VM3>:9090`
- Grafana: `http://<IP_VM3>:3000` (admin/admin)

## 📁 Структура репозитория

```
my-infra-lab/
├── .github/workflows/ci.yml    # CI пайплайн
├── ansible/                    # Ansible playbook и роли
│   ├── playbook.yml
│   ├── inventory.ini.example
│   └── roles/docker/
├── k8s/                        # Kubernetes манифесты
│   ├── namespace.yaml
│   ├── configmap-nginx.yaml
│   ├── secret-postgres.yaml.example
│   ├── pvc-postgres.yaml
│   ├── deployment-nginx.yaml
│   ├── deployment-postgres.yaml
│   ├── service-nginx.yaml
│   └── service-postgres.yaml
├── monitoring/                 # Prometheus + Grafana
│   ├── docker-compose.yml
│   └── prometheus.yml.example
├── html/                       # Статика для Nginx
├── docker-compose.yml          # Базовый запуск
├── nginx.conf                  # Конфиг Nginx
├── .env.example                # Шаблон секретов
└── README.md
```

## ✅ Что реализовно

- [x] Контейнеризация приложения (Nginx + PostgreSQL)
- [x] HTTPS с самоподписанным сертификатом
- [x] Хранение секретов через `.env` (не в Git)
- [x] Автоматизация развёртывания через Ansible
- [x] CI через GitHub Actions (валидация конфигов)
- [x] Мониторинг через Prometheus + Grafana + Node Exporter
- [x] Развёртывание в K3s-кластере из 3 нод
- [x] Self-healing и масштабирование в Kubernetes
- [x] Документация и бейдж CI

## 🎓 Чему я научился

- **Docker:** контейнеризация, multi-container приложения, volumes, сети, секреты.
- **Nginx:** веб-сервер, reverse proxy, HTTPS, редиректы.
- **Ansible:** inventory, playbook, roles, идемпотентность, IaC.
- **CI/CD:** GitHub Actions, workflow, jobs, steps, отладка пайплайнов.
- **Мониторинг:** Prometheus, PromQL, Grafana, дашборды, Node Exporter.
- **Kubernetes:** K3s, pods, deployments, services, configmaps, secrets, PVC, NodePort, self-healing, масштабирование.
- **Linux:** Debian, systemd, SSH, сети, диагностика.
