# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM sider/devon_rex_swift:2.12.0

ARG SWIFTLINT_VERSION=0.38.1

# Build SwiftLint
USER root
RUN SWIFTLINT_BUILD_DIR=/tmp/swiftlint_build && \
    git clone --branch ${SWIFTLINT_VERSION} --single-branch https://github.com/realm/SwiftLint.git ${SWIFTLINT_BUILD_DIR} && \
    cd ${SWIFTLINT_BUILD_DIR} && \
    make install && \
    swiftlint version && \
    rm -rf ${SWIFTLINT_BUILD_DIR}
USER $RUNNER_USER

ARG RUNNERS_DIR=${RUNNER_USER_HOME}/runners

# Install required gems first (due to slow download)
COPY --chown=analyzer_runner:nogroup Gemfile* ${RUNNERS_DIR}/
RUN cd ${RUNNERS_DIR} && \
    bundle config --global jobs 4 && \
    bundle config --global retry 3 && \
    bundle config --local without development:test && \
    bundle config && \
    bundle install
# Copy the main source code
COPY --chown=analyzer_runner:nogroup bin ${RUNNERS_DIR}/bin
COPY --chown=analyzer_runner:nogroup lib ${RUNNERS_DIR}/lib

ENV PATH ${RUNNERS_DIR}/bin:${PATH}

# Run as non-root user
USER $RUNNER_USER
WORKDIR $RUNNER_USER_HOME

ENTRYPOINT ["/usr/bin/timeout", "--signal=SIGUSR2", "--kill-after=10s", "30m", "runners", "--analyzer=swiftlint"]
