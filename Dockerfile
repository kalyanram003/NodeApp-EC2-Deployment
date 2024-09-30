# Use the official Node.js Alpine image as base
FROM node:14-alpine

# Set the working directory inside the container
WORKDIR /app

# Copy package.json and package-lock.json to install dependencies
COPY package*.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application files to the working directory
COPY . .

# Expose port 3000
EXPOSE 3000

# Command to run the Node.js server
CMD ["node", "index.js"]
