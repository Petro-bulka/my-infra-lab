# My Infra Lab - Nginx + PostgreSQL в Docker
Учебный проект по развёртыванию веб-инфраструктуры с использованием Docker Compose.



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

## Переменные окружения

Проект использует `.env` для хранения секретов. Перед запуском скопируйте шаблон:

```bash
cp .env.example .env
```
