# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM sider/devon_rex_npm:2.12.0

ARG RUNNERS_DIR=${RUNNER_USER_HOME}/runners

# Install required gems first (due to slow download)
COPY --chown=analyzer_runner:nogroup Gemfile* ${RUNNERS_DIR}/
RUN cd ${RUNNERS_DIR} && \
    bundle config --global jobs 4 && \
    bundle config --global retry 3 && \
    bundle config --local without development:test && \
    bundle config && \
    bundle install

# Install the default version
COPY --chown=analyzer_runner:nogroup images/eslint/package.json ${RUNNER_USER_HOME}/eslint_package.json
RUN cd ${RUNNER_USER_HOME} && \
    mkdir eslint && \
    mv eslint_package.json eslint/package.json && \
    cd eslint && \
    npm config set ignore-scripts true && \
    npm config set progress false && \
    npm config set package-lock false && \
    npm install && \
    node_modules/.bin/eslint --version
ENV PATH ${RUNNER_USER_HOME}/eslint/node_modules/.bin:${PATH}
# See https://nodejs.org/api/cli.html#cli_node_path_path
ENV NODE_PATH ${RUNNER_USER_HOME}/eslint/node_modules:${NODE_PATH}

# NOTE: ESLint uses a configuration file in the home directory if no other configuration files are found.
#       See https://eslint.org/docs/user-guide/configuring#configuration-cascading-and-hierarchy
COPY --chown=analyzer_runner:nogroup images/eslint/sider_eslintrc.yml ${RUNNER_USER_HOME}/.eslintrc.yml

COPY --chown=analyzer_runner:nogroup images/eslint/custom-eslint-json-formatter.js ${RUNNER_USER_HOME}/

# Copy the main source code
COPY --chown=analyzer_runner:nogroup bin ${RUNNERS_DIR}/bin
COPY --chown=analyzer_runner:nogroup lib ${RUNNERS_DIR}/lib

ENV PATH ${RUNNERS_DIR}/bin:${PATH}

# Run as non-root user
USER $RUNNER_USER
WORKDIR $RUNNER_USER_HOME

ENTRYPOINT ["/usr/bin/timeout", "--signal=SIGUSR2", "--kill-after=10s", "30m", "runners", "--analyzer=eslint"]
