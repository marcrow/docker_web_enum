# Dockerfile.custom
FROM prefecthq/prefect:3.4.3-python3.12

# Installer dépendances système et Go
USER root
RUN apt-get update && apt-get install -y --no-install-recommends \
        ca-certificates curl git build-essential wget unzip \
    && rm -rf /var/lib/apt/lists/*

# Install Go 1.22.3 (or latest stable)
RUN wget https://go.dev/dl/go1.22.3.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.22.3.linux-amd64.tar.gz && \
    rm go1.22.3.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"

ENV GO111MODULE=on

# Installer prefect-shell (et donc prefect si nécessaire) et ses dépendances
RUN pip install --no-cache-dir "prefect[shell]"

# Enregistrer les blocks prefect-shell
RUN prefect block register -m prefect_shell

# Installer assetfinder, subfinder, massdns, dnsx, nuclei dans /opt/tools
ENV GOBIN=/opt/tools
RUN mkdir -p /opt/tools

# 1. Installer assetfinder v0.1.1 (dernier au 26/01/2025)
RUN go install github.com/tomnomnom/assetfinder@v0.1.1

# 2. Installer subfinder v2.7.1 (dernier au 28/04/2025)
RUN go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@v2.7.1

# 3. Installer massdns v1.1.0 (release du 09/03/2024) :contentReference[oaicite:1]{index=1}
WORKDIR /go/src/blechschmidt/massdns
RUN git clone --depth 1 --branch v1.1.0 https://github.com/blechschmidt/massdns.git . \
    && make \
    && cp bin/massdns /opt/tools

# 4. Installer nuclei v3.4.4 (dernier au 16/05/2025)
RUN wget -qO /tmp/nuclei.zip -L \
https://github.com/projectdiscovery/nuclei/releases/download/v3.4.4/nuclei_3.4.4_linux_amd64.zip \
    && unzip /tmp/nuclei.zip -d /opt/tools \
    && rm /tmp/nuclei.zip

# 5. Installer dnsx v1.2.2 (dernier au 02/03/2025)
RUN wget -qO /tmp/dnsx.zip -L \
    https://github.com/projectdiscovery/dnsx/releases/download/v1.2.2/dnsx_1.2.2_linux_amd64.zip \
    && unzip -o /tmp/dnsx.zip -d /opt/tools \
    && rm /tmp/dnsx.zip


# Ajouter /opt/tools dans le PATH
ENV PATH="/opt/tools:${PATH}"


# Repasser à l’utilisateur non-root (selon l’image prefect)
USER chromatography