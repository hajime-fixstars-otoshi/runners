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
COPY --chown=analyzer_runner:nogroup images/stylelint/package.json ${RUNNER_USER_HOME}/stylelint_package.json
RUN cd ${RUNNER_USER_HOME} && \
    mkdir stylelint && \
    mv stylelint_package.json stylelint/package.json && \
    cd stylelint && \
    npm config set ignore-scripts true && \
    npm config set progress false && \
    npm config set package-lock false && \
    npm install && \
    node_modules/.bin/stylelint --version
ENV PATH ${RUNNER_USER_HOME}/stylelint/node_modules/.bin:${PATH}
# See https://nodejs.org/api/cli.html#cli_node_path_path
ENV NODE_PATH ${RUNNER_USER_HOME}/stylelint/node_modules:${NODE_PATH}

# NOTE: Install the older version to run `stylelint-config-recommended` with stylelint v8.
RUN cd ${RUNNER_USER_HOME} && \
    mkdir stylelint-config-recommended.old && \
    cd stylelint-config-recommended.old && \
    npm install stylelint-config-recommended@2

COPY --chown=analyzer_runner:nogroup \
     images/stylelint/sider_recommended_config.old.yaml \
     images/stylelint/sider_recommended_config.yaml \
     images/stylelint/sider_recommended_stylelintignore \
     ${RUNNER_USER_HOME}/

# Copy the main source code
COPY --chown=analyzer_runner:nogroup bin ${RUNNERS_DIR}/bin
COPY --chown=analyzer_runner:nogroup lib ${RUNNERS_DIR}/lib

ENV PATH ${RUNNERS_DIR}/bin:${PATH}

# Run as non-root user
USER $RUNNER_USER
WORKDIR $RUNNER_USER_HOME

ENTRYPOINT ["/usr/bin/timeout", "--signal=SIGUSR2", "--kill-after=10s", "30m", "runners", "--analyzer=stylelint"]
