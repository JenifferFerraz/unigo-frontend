# unigo-frontend/Dockerfile

# Estágio de build: Cria os arquivos estáticos do Flutter Web
FROM instrumentisto/flutter:latest AS flutter_build

WORKDIR /app

# Copia todo o projeto Flutter para dentro do contêiner
COPY . .

# Garante que as dependências sejam baixadas
RUN flutter pub get

# Constrói o projeto Flutter para web
# O output padrão é 'build/web'
RUN flutter build web

# Estágio de produção: Serve os arquivos estáticos com Nginx
FROM nginx:alpine

# Remove a configuração padrão do Nginx
RUN rm /etc/nginx/conf.d/default.conf

# Copia uma configuração customizada do Nginx (opcional, mas recomendado)
# Você precisaria criar este arquivo 'nginx.conf' na sua pasta 'unigo-frontend'
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Se não copiar um nginx.conf, um default simples como este pode ser usado:
RUN echo "server { listen 80; location / { root /usr/share/nginx/html; try_files \$uri \$uri/ /index.html; } }" > /etc/nginx/conf.d/default.conf

# Copia os arquivos construídos do Flutter (do estágio 'flutter_build')
COPY --from=flutter_build /app/build/web /usr/share/nginx/html

# Expõe a porta 80 que o Nginx escuta
EXPOSE 80

# Comando para iniciar o Nginx em foreground
CMD ["nginx", "-g", "daemon off;"]