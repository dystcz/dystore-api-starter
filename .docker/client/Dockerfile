# Specify base image
FROM node:20

# Specify working directory
WORKDIR /app

# Copy application files
COPY . .

# Install ni
RUN npm i -g @antfu/ni

# Install dependencies
RUN ni

# Run build
RUN nr build

# Specify host variable
ENV HOST 0.0.0.0

# Expose Nuxt port
EXPOSE 3000

# Specify image command
CMD ["node", ".output/server/index.mjs"]
