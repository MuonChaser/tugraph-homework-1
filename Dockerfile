FROM nginx:stable@sha256:d5792f71a9496b833bc08ea834a758c46e2b6a6306c10f4be926f38a656cdc1c
RUN apt-get update && apt-get install -y --no-install-recommends rpm2cpio cpio libgomp1 libgfortran5 ca-certificates && rm -rf /var/lib/apt/lists/*
COPY vendor/tugraph-4.5.1-1.el7.x86_64.rpm /tmp/tugraph.rpm
RUN cd / && rpm2cpio /tmp/tugraph.rpm | cpio -idmu && rm /tmp/tugraph.rpm
ENV LD_LIBRARY_PATH=/usr/local/lib64/lgraph
WORKDIR /workspace
EXPOSE 7070 7687 9090
ENTRYPOINT ["/usr/local/bin/lgraph_server"]
CMD ["-c", "/workspace/config/lgraph.json", "-d", "run"]
