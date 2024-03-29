# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM sider/devon_rex_python:2.12.0 AS builder

# NOTE: The reason using Python image: when setting `MATCHCOMPILER=yes`, Python is used to optimise cppcheck.
#
# See https://github.com/danmar/cppcheck#gnu-make

ARG CPPCHECK_VERSION=1.90
USER root
RUN cd /tmp && \
    curl -sSL https://github.com/danmar/cppcheck/archive/${CPPCHECK_VERSION}.tar.gz | tar -xz && \
    cd cppcheck-${CPPCHECK_VERSION} && \
    make install -s \
      MATCHCOMPILER=yes \
      FILESDIR=/usr/share/cppcheck \
      HAVE_RULES=yes \
      CXXFLAGS="-O2 -DNDEBUG -Wall -Wno-sign-compare -Wno-unused-function" && \
    rm -rf cppcheck-${CPPCHECK_VERSION}

FROM sider/devon_rex_base:2.12.0

COPY --from=builder /usr/share/cppcheck /usr/share/cppcheck
COPY --from=builder /usr/bin/cppcheck /usr/bin/cppcheck

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

ENTRYPOINT ["/usr/bin/timeout", "--signal=SIGUSR2", "--kill-after=10s", "30m", "runners", "--analyzer=cppcheck"]
