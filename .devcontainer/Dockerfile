FROM blang/latex:ubuntu

# Avoid warnings by switching to noninteractive
ENV DEBIAN_FRONTEND=noninteractive

# Update the system and install Pandoc and make
RUN apt-get update \
    && apt-get -y install --no-install-recommends pandoc make \
    chktex aspell \
    && apt-get clean -y \
    && rm -rf /var/lib/apt/lists/*

# Switch back to dialog for any ad-hoc use of apt-get
ENV DEBIAN_FRONTEND=dialog
