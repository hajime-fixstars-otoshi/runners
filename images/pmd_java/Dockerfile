# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM sider/devon_rex_java:2.0.3

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


ENV PMD_VERSION 6.17.0
USER root
RUN curl -SL https://github.com/pmd/pmd/releases/download/pmd_releases%2F${PMD_VERSION}/pmd-bin-${PMD_VERSION}.zip > pmd-bin-${PMD_VERSION}.zip \
    && unzip pmd-bin-${PMD_VERSION}.zip \
    && mv pmd-bin-${PMD_VERSION} /usr/local/pmd \
    && rm pmd-bin-${PMD_VERSION}.zip

USER $RUNNER_USER

ENTRYPOINT ["node_harness", "--analyzer=pmd_java"]