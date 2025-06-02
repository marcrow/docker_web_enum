# Dockerfile pour Prefect Hunter - passive & active tools
# Base builder pour compiler les outils Go
FROM golang:1.24-bullseye AS builder

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOBIN=/go/bin \
    PATH=$GOBIN:$PATH

RUN apt-get update && apt-get install -y --no-install-recommends \
unzip \
git \
&& rm -rf /var/lib/apt/lists/*

# 1. Installer assetfinder v0.1.1 (dernier au 26/01/2025)
RUN go install github.com/tomnomnom/assetfinder@v0.1.1

# 2. Installer subfinder v2.7.1 (dernier au 28/04/2025)
RUN go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@v2.7.1

# 3. Installer massdns v1.1.0 (release du 09/03/2024) :contentReference[oaicite:1]{index=1}
WORKDIR /go/src/blechschmidt/massdns
RUN git clone --depth 1 --branch v1.1.0 https://github.com/blechschmidt/massdns.git . \
    && make \
    && cp bin/massdns /go/bin

# 4. Installer nuclei v3.4.4 (dernier au 16/05/2025)
RUN wget -qO /tmp/nuclei.zip -L \
https://github.com/projectdiscovery/nuclei/releases/download/v3.4.4/nuclei_3.4.4_linux_amd64.zip \
    && unzip /tmp/nuclei.zip -d /go/bin \
    && rm /tmp/nuclei.zip

# 5. Installer dnsx v1.2.2 (dernier au 02/03/2025)
RUN wget -qO /tmp/dnsx.zip -L \
    https://github.com/projectdiscovery/dnsx/releases/download/v1.2.2/dnsx_1.2.2_linux_amd64.zip \
    && unzip -o /tmp/dnsx.zip -d /go/bin \
    && rm /tmp/dnsx.zip


# 6. Placeholder pour ajouter ffuf (dernier au jour J, ex : v2.0.0)
# RUN go install github.com/ffuf/ffuf@latest

# Création de l’image finale minimale
FROM debian:bullseye-slim

RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    wget \
    && rm -rf /var/lib/apt/lists/*

ENV PATH=/opt/tools:$PATH
RUN mkdir -p /opt/tools

# Copie des binaires compilés depuis builder
COPY --from=builder /go/bin/assetfinder /opt/tools/
COPY --from=builder /go/bin/subfinder /opt/tools/
COPY --from=builder /go/bin/massdns /opt/tools/
COPY --from=builder /go/bin/nuclei /opt/tools/
COPY --from=builder /go/bin/dnsx /opt/tools/
# COPY --from=builder /go/bin/ffuf /opt/tools/    <-- décommenter si ajouté ultérieurement

WORKDIR /workspace

# Entrypoint neutre ; remplacé par chaque commande via "docker exec"
ENTRYPOINT ["/bin/bash"]
