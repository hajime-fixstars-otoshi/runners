require_relative "test_helper"

class HarnessTest < Minitest::Test
  include TestHelper

  Harness = Runners::Harness
  Processor = Runners::Processor
  Results = Runners::Results
  Issue = Runners::Issue
  Location = Runners::Location
  Analyzer = Runners::Analyzer
  TraceWriter = Runners::TraceWriter
  Workspace = Runners::Workspace
  Options = Runners::Options

  def trace_writer
    @trace_writer ||= TraceWriter.new(writer: [])
  end

  def with_options(head: Pathname(__dir__).join("data/foo.tgz"))
    with_runners_options_env(source: { head: head }) do
      yield Runners::Options.new(StringIO.new, StringIO.new)
    end
  end

  def with_working_dir
    Dir.mktmpdir do |dir|
      yield Pathname(dir)
    end
  end

  class TestProcessor < Processor
    def analyze(changes)
      Results::Success.new(guid: guid, analyzer: Analyzer.new(name: "Test", version: "0.1.3"))
    end
  end

  class BrokenProcessor < Processor
    def initialize(*args)
      raise StandardError, "broken!"
    end
  end

  def test_run
    with_working_dir do |working_dir|
      with_options do |options|
        mock.proxy(Workspace).prepare(options: options, working_dir: working_dir, trace_writer: trace_writer)
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: TestProcessor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)

        result = harness.run
        assert_instance_of Results::Success, result
      end
    end
  end

  def test_run_when_using_broken_processor
    with_working_dir do |working_dir|
      with_options do |options|
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: BrokenProcessor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)

        result = harness.run
        assert_instance_of Results::Error, result
        assert_equal(
          ["broken! (StandardError)"],
          trace_writer.writer.filter { |e| e[:trace] == :error }.map { |e| e[:message] },
        )
      end
    end
  end

  def test_run_filters_issues
    processor = Class.new(Processor) do
      def analyze(changes)
        Results::Success.new(guid: guid, analyzer: Analyzer.new(name: "Test", version: "0.1.3")).tap do |result|
          result.add_issue Issue.new(
            path: Pathname("test/cli/test_test.rb"),
            location: Location.new(start_line: 0),
            id: "id1",
            message: "...",
          )
          result.add_issue Issue.new(
            path: Pathname("no_such_file"),
            location: Location.new(start_line: 0),
            id: "id2",
            message: "...",
          )
          result.add_issue Issue.new(
            path: Pathname("taggeing_test.rb"),
            location: Location.new(start_line: 0),
            id: "id3",
            message: "...",
          )
        end
      end
    end

    with_working_dir do |working_dir|
      with_options do |options|
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: processor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)

        result = harness.run

        assert_instance_of Results::Success, result
        assert_equal [Issue.new(
          path: Pathname("test/cli/test_test.rb"),
          location: Location.new(start_line: 0),
          id: "id1",
          message: "...",
        )], result.issues
      end
    end
  end

  def test_run_when_root_dir_not_found
    with_working_dir do |working_dir|
      (working_dir / "sider.yml").write(YAML.dump({ "linter" => { TestProcessor.ci_config_section_name => { "root_dir" => "foo" } } }))
      with_options do |options|
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: TestProcessor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)

        assert_instance_of Results::Failure, harness.run
      end
    end
  end

  def test_run_when_ci_config_is_broken
    with_working_dir do |working_dir|
      (working_dir / "sider.yml").write('1: 1:')
      with_options do |options|
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: TestProcessor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)

        result = harness.run
        assert_instance_of Results::Failure, result
        assert_equal "Your `sider.yml` file may be broken (line 1, column 5).", result.message
      end
    end
  end

  def test_ensure_result_returns_error_result_if_raised
    with_working_dir do |working_dir|
      with_options do |options|
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: TestProcessor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)

        result = harness.ensure_result do
          JSON.parse("something wrong")
        end
        assert_instance_of Results::Error, result
        assert_instance_of JSON::ParserError, result.exception
        assert_equal(
          [{ trace: :error, message: "767: unexpected token at 'something wrong' (JSON::ParserError)" }],
          trace_writer.writer.map { |entry| entry.slice(:trace, :message) },
        )
      end
    end
  end

  def test_ensure_result_checks_validity_of_issues
    with_working_dir do |working_dir|
      with_options do |options|
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: TestProcessor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)

        result = harness.ensure_result do
          Results::Success.new(guid: nil, analyzer: Analyzer.new(name: "foo", version: "1.0.3"))
        end
        assert_instance_of Results::Error, result
        assert_instance_of Harness::InvalidResult, result.exception
        assert_equal "Invalid result: #{result.exception.result.inspect}", result.exception.message
        assert_equal [], trace_writer.writer
      end
    end
  end

  def test_setup_analyze
    processor = Class.new(Processor) do
      def setup
        (current_dir + "touch").write("#setup should be called before #analyze")
        yield
      end

      def analyze(changes)
        (current_dir + "touch").file? or raise
        Results::Success.new(guid: guid, analyzer: Analyzer.new(name: "Test", version: "0.1.3"))
      end
    end

    with_working_dir do |working_dir|
      with_options do |options|
        harness = Harness.new(guid: SecureRandom.uuid, processor_class: processor,
                              options: options, working_dir: working_dir, trace_writer: trace_writer)
        result = harness.run
        assert_instance_of Results::Success, result
      end
    end
  end
end
