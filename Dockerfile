FROM nginx:alpine

# Копируем свой конфиг и статику
COPY nginx.conf /etc/nginx/nginx.conf
COPY html/index.html /usr/share/nginx/html/index.html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
