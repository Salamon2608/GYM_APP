FROM node:20-alpine

# Set working directory
WORKDIR /usr/src/app

# Install dependencies first (leverage Docker cache)
COPY package*.json ./
RUN npm ci --only=production

# Copy application code
COPY . .

# Create uploads directory if not present
RUN mkdir -p uploads

# Expose port
EXPOSE 3000

# Set environment
ENV NODE_ENV=production
ENV PORT=3000

# Run the app
CMD ["node", "server.js"]
