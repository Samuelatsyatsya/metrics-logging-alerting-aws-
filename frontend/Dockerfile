FROM node:18-alpine AS development

WORKDIR /app

# Copy package files
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy application code
COPY . .

# Drop root privileges for runtime (Trivy DS-0002)
RUN chown -R node:node /app
USER node

# Start application
CMD ["npm", "run", "dev"]
