FROM andreadotti/geant4-base:latest

MAINTAINER Andrea Dotti (adotti@slac.stanford.edu)

RUN apt update -y && apt install -y libssl-dev libffi-dev \
		     python-dev build-essential git jq \
		     python-pip sudo vim

RUN pip install --upgrade pip && pip install --prefix /usr/local --upgrade blobxfer
RUN pip install --prefix /usr/local azure-cli

# Batch shipuard requires sudo for installation
# and cannot be installed as root
RUN useradd -ms /bin/bash g4-azure
RUN echo "g4-azure ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers
RUN cat /etc/sudoers && ls /etc/sudoers.d
USER g4-azure
WORKDIR /home/g4-azure

RUN git clone https://github.com/Azure/batch-shipyard.git
RUN cd batch-shipyard && ./install.sh -e shipyard.venv

COPY az-batch config.json credentials-template.json jobs-example.json pool.json summary.json *.md /geant4-val-azure/
COPY ProcessTest /geant4-val-azure/ProcessTest/

ENV PATH="$PATH:/geant4-val-azure:/home/g4-azure/batch-shipyard"



	 

