# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM sider/devon_rex_go:2.12.0

ARG RUNNERS_DIR=${RUNNER_USER_HOME}/runners

# Install required gems first (due to slow download)
COPY --chown=analyzer_runner:nogroup Gemfile* ${RUNNERS_DIR}/
RUN cd ${RUNNERS_DIR} && \
    bundle config --global jobs 4 && \
    bundle config --global retry 3 && \
    bundle config --local without development:test && \
    bundle config && \
    bundle install

ARG LINT_TOOL_VERSION="3.0.0"

USER root
RUN curl -L https://github.com/alecthomas/gometalinter/releases/download/v${LINT_TOOL_VERSION}/gometalinter-${LINT_TOOL_VERSION}-linux-amd64.tar.gz | \
    tar -xzC . && \
    cd gometalinter-${LINT_TOOL_VERSION}-linux-amd64/ && \
    rm COPYING README.md && \
    mv * /usr/local/bin/ && \
    cd .. && \
    rm -r gometalinter-${LINT_TOOL_VERSION}-linux-amd64/
USER $RUNNER_USER

# Copy the main source code
COPY --chown=analyzer_runner:nogroup bin ${RUNNERS_DIR}/bin
COPY --chown=analyzer_runner:nogroup lib ${RUNNERS_DIR}/lib

ENV PATH ${RUNNERS_DIR}/bin:${PATH}

# Run as non-root user
USER $RUNNER_USER
WORKDIR $RUNNER_USER_HOME

ENTRYPOINT ["/usr/bin/timeout", "--signal=SIGUSR2", "--kill-after=10s", "30m", "runners", "--analyzer=go_vet"]
