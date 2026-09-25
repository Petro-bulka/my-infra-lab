# My Infra Lab - Nginx + PostgreSQL в Docker
Учебный проект по развёртыванию веб-инфраструктуры с использованием Docker Compose.
![CI](https://github.com/Petro-bulka/my-infra-lab/actions/workflows/ci.yml/badge.svg)


## Цель проекта
Отработать навыки:
- Работы с Docker и Docker Compose
- Настройки Nginx как веб-сервера
- Развёртывания PostgreSQL с сохранением данных через Volumes
- Изоляции сервисов через внутреннюю сеть Docker


## Стек
- Debian 13 (хостовая ОС)
- Docker / Docker Compose
- Nginx (alpine)
- PostgreSQL 15 (alpine)

## Запуск
```bash
git clone https://github.com/Petro-bulka/my-infra-lab.git
cd my-infra-lab
docker compose up -d
```
## Автоматизация через Ansible

Развёртывание проекта автоматизировано через Ansible. Playbook устанавливает Docker, клонирует репозиторий, генерирует SSL-сертификат и запускает стек на чистой Debian.

### Подготовка

1. Установите Ansible на управляющем узле:

```bash
sudo apt install ansible -y
```

## Переменные окружения

Проект использует `.env` для хранения секретов. Перед запуском скопируйте шаблон:

```bash
cp .env.example .env
```
## HTTPS

Проект использует самоподписанный SSL-сертификат. Перед запуском сгенерируйте его:

```bash
mkdir certs
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
  -keyout certs/nginx.key -out certs/nginx.crt \
  -subj "/C=RU/ST=Moscow/L=Moscow/O=MyLab/CN=localhost"
```
