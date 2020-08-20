FROM mcr.microsoft.com/quantum/iqsharp-base:latest

ENV IQSHARP_HOSTING_ENV=QRAM_DOCKER
USER root
RUN pip install RISE

# Make sure the contents of our repo are in ${HOME}.
# These steps are required for use on mybinder.org.
COPY . ${HOME}
RUN chown -R ${USER} ${HOME}

# Drop back down to user permissions for things that don't need it.
USER ${USER}

RUN dotnet nuget add source ${HOME}/src/bin/Debug/ -n "Qram" && \
    dotnet pack ${HOME}/src/qram.csproj
