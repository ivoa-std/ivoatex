#This is a dockerfile for building the ivoatex documentation
#it is designed to be used in a GitHub Actions workflow, but can also be used locally for development and testing.

FROM ubuntu:24.04 AS build

RUN apt-get update && apt-get install -y build-essential

WORKDIR /workspace

COPY ./tth_C/*  /workspace/

RUN gcc -o tth tth.c

FROM ubuntu:24.04

COPY --from=build /workspace/tth /usr/local/bin/tth

ENV DEBIAN_FRONTEND=noninteractive \
    PIP_NO_CACHE_DIR=1 \
    PYTHONDONTWRITEBYTECODE=1

# Base tooling + full document build dependencies used by this repo.
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    git \
    make \
    curl \
    python3 \
    python3-pip \
    python3-venv \
    openjdk-17-jre-headless \
    texlive-latex-base \
    texlive-latex-recommended \
    texlive-latex-extra \
    texlive-fonts-recommended \
    texlive-plain-generic \
    librsvg2-bin \
    latexmk \
    inkscape \
    pdftk \
    xsltproc \
    cm-super \
    pdf2svg \
    plantuml \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

# get the latest version of pandoc from github releases and install it
RUN curl -L -o /tmp/pandoc.deb  https://github.com/jgm/pandoc/releases/download/3.11/pandoc-3.11-1-amd64.deb\
    && dpkg -i /tmp/pandoc.deb \
    && rm /tmp/pandoc.deb

# Pre-install Python deps
COPY requirements.txt /tmp/requirements.txt
RUN python3 -m pip install --upgrade pip \
    && python3 -m pip install -r /tmp/requirements.txt \
    && rm -f /tmp/requirements.txt

CMD ["bash"]
