FROM node:18-alpine
WORKDIR /app

# Install dependencies first
COPY package*.json ./
RUN npm install 

# Copy source code
COPY . .

# Create non-root user
RUN addgroup -g 1001 -S nodejs
RUN adduser -S nodejs -u 1001
USER nodejs

CMD ["node", "server.js"]