FROM mcr.microsoft.com/quantum/iqsharp-base:latest

ENV IQSHARP_HOSTING_ENV=QRAM_DOCKER
# Make sure the contents of our repo are in ${HOME}.
# These steps are required for use on mybinder.org.
USER root

RUN apt-get -y update && \
    apt-get -y install \
        g++ && \
    apt-get clean && rm -rf /var/lib/apt/lists/ 

COPY . ${HOME}
RUN chown -R ${USER} ${HOME}

RUN dotnet nuget add source ${HOME}/src/bin/Debug/ -n "Qram" && \
    dotnet pack ${HOME}/src/qram.csproj

USER ${USER}
