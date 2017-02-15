FROM andreadotti/geant4-base:latest

MAINTAINER Andrea Dotti (adotti@slac.stanford.edu)

RUN apt update -y && apt install -y libssl-dev libffi-dev \
		     python-dev build-essential git jq \
		     python-pip sudo

RUN pip install --upgrade pip && pip install --upgrade blobxfer
RUN pip install --user azure-cli
RUN git clone https://github.com/Azure/batch-shipyard.git
#Fix preventing running as root
RUN cd batch-shipyard && \
    sed '0,/exit/{s/exit/#exit/}' install.sh > install-new.sh && \
    chmod +x install-new.sh && \
    ./install-new.sh && cd ../ && rm -rf batch-shipyard

RUN cd / && git clone https://github.com/andreadotti/geant4-val-azure.git 

ENV PATH="$PATH:/geant4-val-azure:/batch-shipyard:~/.local/bin"



	 

