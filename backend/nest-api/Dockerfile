# Base image
FROM node:20-alpine

# Create app directory
WORKDIR /usr/src/app

# Copy dependency definitions
COPY package*.json ./

# Install dependencies (only production for smaller size, but let's keep all for now to be safe)
RUN npm install

# Copy all files (including the dist folder we will build locally)
COPY . .

# Generate Prisma Client
RUN npx prisma generate

# Expose port
EXPOSE 3000

# Start the application using the local dist folder
CMD [ "npm", "run", "start:prod" ]