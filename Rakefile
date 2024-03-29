require "rake/testtask"
require 'erb'
require "aufgaben/release"
require "aufgaben/bump/ruby"
require_relative "lib/tasks/bump/analyzers"
require_relative "lib/tasks/bump/devon_rex"
require_relative "lib/tasks/docker/timeout_test"

Aufgaben::Release.new do |t|
  t.files = ["lib/runners/version.rb"]
end

Aufgaben::Bump::Ruby.new do |t|
  t.files = %w[
    .ruby-version
    .circleci/config.yml
    .github/workflows/bump_analyzers.yml
  ]
end

ANALYZERS = begin
  Dir.chdir("images") do
    Dir.glob("*").select { |f| File.directory? f }.freeze
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << "test"
  t.libs << "lib"
  t.test_files = FileList['test/**/*_test.rb'].exclude(%r{^test/smokes})
end

task :default => [:test, :typecheck]

task :typecheck do
  # FIXME: Must check all files.
  files = Dir.glob("lib/runners/**/*.rb").reject { |f| f.include? "processor/" }
  sh "steep", "check", *files
end

namespace :dockerfile do
  def render_erb(file)
    ERB.new(File.read(file)).result.chomp
  end

  desc 'Generate Dockerfile from a template'
  task :generate do
    # TODO: `COPY --chown=${RUNNER_USER}:${RUNNER_GROUP}` format has been available since Docker v19.03.4.
    #       However, CircleCI does not support the Docker version...
    ENV["RUNNER_CHOWN"] = "analyzer_runner:nogroup"

    ANALYZERS.each do |analyzer|
      backup_analyzer = ENV['ANALYZER']
      ENV['ANALYZER'] = analyzer
      path = Pathname('images') / analyzer
      template = ERB.new((path / 'Dockerfile.erb').read)
      result = <<~EOD
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        # NOTE: DO *NOT* EDIT THIS FILE.  IT IS GENERATED.
        # PLEASE UPDATE Dockerfile.erb INSTEAD OF THIS FILE
        # !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
        #{template.result.chomp}
      EOD
      File.write(path / 'Dockerfile', result)
    ensure
      if backup_analyzer
        ENV['ANALYZER'] = backup_analyzer
      else
        ENV.delete 'ANALYZER'
      end
    end
  ensure
    ENV.delete "RUNNER_CHOWN"
  end

  desc 'Verify Dockerfile is committed'
  task :verify do
    system('git diff --exit-code') or
      abort "\nError: Run `bundle exec rake dockerfile:generate` and include the changes in commit"
  end
end

namespace :docker do
  def image_name(image_tag = tag)
    "sider/runner_#{analyzer}:#{image_tag}"
  end

  def build_context
    Pathname('images') / analyzer
  end

  def analyzer
    key = 'ANALYZER'
    ENV[key].tap do |value|
      abort <<~MSG if value.nil? || value.empty?
        Error: `#{key}` environment variable must be required. For example, run as follow:

            $ #{key}=rubocop bundle exec rake docker:build
      MSG
    end
  end

  def tag
    ENV.fetch('TAG', 'dev')
  end

  def docker_user
    ENV.fetch('DOCKER_USER')
  end

  def docker_password
    ENV.fetch('DOCKER_PASSWORD')
  end

  desc 'Run docker build'
  task :build => 'dockerfile:generate' do
    sh "docker", "build", "--tag", image_name, "--file", "#{build_context}/Dockerfile", "."
  end

  desc 'Run smoke test on Docker'
  task :smoke do
    sh "bin/runners_smoke", image_name, "test/smokes/#{analyzer}/expectations.rb"
  end

  desc 'Run docker push'
  task :push, [:tag] do |_task, args|
    arg_tag = args.fetch(:tag, "latest")

    sh "docker", "login", "--username", docker_user, "--password", docker_password
    begin
      sh "docker", "tag", image_name, image_name(arg_tag)
      sh "docker", "push", image_name
      sh "docker", "push", image_name(arg_tag)
    ensure
      sh "docker", "logout"
    end
  end

  desc 'Run interactive shell in the specified Docker container'
  task :shell do
    sh "docker", "run", "-it", "--rm", "--entrypoint=bash", image_name
  end
end
