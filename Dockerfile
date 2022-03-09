FROM photon:4.0

COPY inject.sh /inject.sh

RUN tdnf update -y && tdnf install -y jq openssh-clients shadow && \
    curl -LO "https://storage.googleapis.com/kubernetes-release/release/$(curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt)/bin/linux/amd64/kubectl" && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl && \
    chmod +x /inject.sh && \
    groupadd inject && useradd -G inject -m -d /home/inject/ inject

ENTRYPOINT [ "/inject.sh" ]

 
