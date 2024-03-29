# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
# NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
# PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
# !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
FROM sider/devon_rex_ruby:2.12.0

# NOTE: RuboCop 0.60.0 does not work on Ruby 2.6, so install and use Ruby 2.5 instead.
#       See https://github.com/sider/runners/issues/57#issuecomment-530858769
ENV GLOBAL_RUBY_VERSION 2.5.7
RUN rbenv install $GLOBAL_RUBY_VERSION && \
    rbenv global $GLOBAL_RUBY_VERSION && \
    rbenv versions && \
    test $(ruby -e 'puts RUBY_VERSION') = "$GLOBAL_RUBY_VERSION" && \
    gem install bundler --version $BUNDLER1_VERSION && \
    gem install bundler --version $BUNDLER2_VERSION && \
    bundle -v | grep -q "$BUNDLER2_VERSION"

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
COPY --chown=analyzer_runner:nogroup images/rubocop/Gemfile ${RUNNER_USER_HOME}/rubocop_Gemfile
RUN cd ${RUNNER_USER_HOME} && \
    mkdir rubocop && \
    mv rubocop_Gemfile rubocop/Gemfile && \
    cd rubocop && \
    bundle install --system --gemfile=Gemfile && \
    rbenv rehash && \
    cd ${RUNNER_USER_HOME} && \
    rm -rf rubocop && \
    gem list rubocop

COPY --chown=analyzer_runner:nogroup images/rubocop/default_rubocop.yml ${RUNNER_USER_HOME}/

# Copy the main source code
COPY --chown=analyzer_runner:nogroup bin ${RUNNERS_DIR}/bin
COPY --chown=analyzer_runner:nogroup lib ${RUNNERS_DIR}/lib

ENV PATH ${RUNNERS_DIR}/bin:${PATH}

# Run as non-root user
USER $RUNNER_USER
WORKDIR $RUNNER_USER_HOME

ENTRYPOINT ["/usr/bin/timeout", "--signal=SIGUSR2", "--kill-after=10s", "30m", "runners", "--analyzer=rubocop"]
