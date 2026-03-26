FROM python:3.11-slim

# Set working directory
WORKDIR /app

# Install system dependencies including espeak and build tools for llama-cpp
RUN apt-get update && apt-get install -y \
    espeak \
    libsndfile1 \
    git \
    build-essential \
    cmake \
    curl \
    libopenblas-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy requirements first for better caching
COPY requirements.txt requirements-optional.txt ./

# Install CPU-only torch/torchaudio first, then remaining Python dependencies
RUN pip install --no-cache-dir --index-url https://download.pytorch.org/whl/cpu \
    torch==2.8.0 torchaudio==2.8.0 && \
    pip install --no-cache-dir -r requirements.txt && \
    pip install --no-cache-dir flask

# Install optional dependencies (llama-cpp-python, onnxruntime)
# Use CMAKE_ARGS for CPU-only build (faster compilation)
RUN CMAKE_ARGS="-DLLAMA_BLAS=ON -DLLAMA_BLAS_VENDOR=OpenBLAS" \
    pip install --no-cache-dir llama-cpp-python && \
    pip install --no-cache-dir onnxruntime

# Copy the entire project
COPY . .

# Create necessary directories
RUN mkdir -p /app/web_interface/uploads /app/web_interface/outputs

# Expose port
EXPOSE 5000

# Set environment variables
ENV FLASK_APP=web_interface/app.py
ENV PYTHONUNBUFFERED=1

# Run the application
CMD ["python", "web_interface/app.py"]