# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM sider/devon_rex_npm:2.0.3

ARG NODE_HARNESS_DIR=$RUNNER_USER_HOME/node_harness
COPY Gemfile* Rakefile $NODE_HARNESS_DIR/
COPY bin ${NODE_HARNESS_DIR}/bin
COPY lib ${NODE_HARNESS_DIR}/lib
USER root
RUN chown -R $RUNNER_USER: $NODE_HARNESS_DIR
USER $RUNNER_USER

RUN cd $NODE_HARNESS_DIR && bundle install
ENV BUNDLE_GEMFILE $NODE_HARNESS_DIR/Gemfile
ENV PATH $NODE_HARNESS_DIR/bin:$PATH


ARG ESLINT_VERSION=5.16.0

# Install eslint globally
USER root
RUN npm install -g eslint@${ESLINT_VERSION}
USER $RUNNER_USER

# NOTE: ESLint uses a configuration file in the home directory if no other configuration files are found.
#       See https://eslint.org/docs/user-guide/configuring#configuration-cascading-and-hierarchy
COPY images/eslint/sider_eslintrc.yml $RUNNER_USER_HOME/.eslintrc.yml

ENTRYPOINT ["node_harness", "--analyzer=eslint"]