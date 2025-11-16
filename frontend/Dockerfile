FROM python:3.11-alpine

WORKDIR /app

# Copy HTML and JS files
COPY index.html .
COPY app.js .

# Expose port 80
EXPOSE 80

# Use Python's built-in HTTP server
CMD ["python", "-m", "http.server", "80"]

