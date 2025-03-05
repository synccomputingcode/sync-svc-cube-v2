FROM cubejs/cube:v1.1.9

RUN apt-get update \
        && apt-get install -y --no-install-recommends curl \
        && apt-get clean \
        && rm -rf /var/lib/apt/lists/*

COPY cube.js cube.js
COPY fetch.js fetch.js
RUN mkdir model
COPY model/ model/
