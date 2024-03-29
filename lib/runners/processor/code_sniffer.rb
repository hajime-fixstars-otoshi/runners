module Runners
  class Processor::CodeSniffer < Processor
    include PHP

    Schema = StrongJSON.new do
      let :runner_config, Schema::RunnerConfig.base.update_fields { |fields|
        fields.merge!({
                        version: enum?(string, numeric),
                        dir: string?,
                        standard: string?,
                        extensions: string?,
                        encoding: string?,
                        ignore: string?,
                        # DO NOT ADD ANY OPTION under `options`.
                        options: optional(object(
                                            dir: string?,
                                            standard: string?,
                                            extensions: string?,
                                            encoding: string?,
                                            ignore: string?
                                          ))
                      })
      }

      let :issue, object(
        type: string,
        severity: integer,
        fixable: boolean,
      )
    end

    def self.ci_config_section_name
      "code_sniffer"
    end

    def setup
      add_warning_if_deprecated_options([:options], doc: "https://help.sider.review/tools/php/codesniffer")
      yield
    end

    def analyze(changes)
      ensure_runner_config_schema(Schema.runner_config) do |config|
        check_runner_config(config) do |options, target|
          run_analyzer(options, target)
        end
      end
    end

    private

    def check_runner_config(config)
      if config[:version].to_i == 2
        add_warning("Sider has no longer supported PHP_CodeSniffer v2. Sider executes v3 even if putting `2` as `version` option.", file: ci_config_path_name)
      end

      options = additional_options(config)
      target = directory(config)

      yield options, target
    end

    def analyzer_name
      "code_sniffer"
    end

    def analyzer_bin
      "phpcs"
    end

    def additional_options(config)
      # If a repository doesn't have `sideci.yml`, use default configuration with `default_sideci_options` method.
      if config.empty?
        default_sideci_options[:options].map do |k, v|
          "--#{k}=#{v}"
        end
      else
        standard = standard_option(config)
        extensions = extensions_option(config)
        encoding = encoding_option(config)
        ignore = ignore_option(config)

        [standard, extensions, encoding, ignore].compact
      end
    end

    def standard_option(config)
      standard = config[:standard] || config.dig(:options, :standard) || default_sideci_options.dig(:options, :standard)
      "--standard=#{standard}"
    end

    def extensions_option(config)
      extensions = config[:extensions] || config.dig(:options, :extensions) || default_sideci_options.dig(:options, :extensions)
      "--extensions=#{extensions}"
    end

    def encoding_option(config)
      encoding = config[:encoding] || config.dig(:options, :encoding)
      "--encoding=#{encoding}" if encoding
    end

    def ignore_option(config)
      ignore = config[:ignore] || config.dig(:options, :ignore)
      "--ignore=#{ignore}" if ignore
    end

    def directory(config)
      config[:dir] || config.dig(:options, :dir) || default_sideci_options[:dir]
    end

    def default_sideci_options
      @default_sideci_options ||=
        case php_framework
        when :CakePHP
          {
            options: {
              standard: 'CakePHP',
              extensions: 'php',
            },
            dir: 'app/',
          }
        when :Symfony
          {
            options: {
              standard: 'Symfony',
              extensions: 'php',
            },
            dir: 'src/',
          }
        else
          {
            options: {
              standard: 'PSR2',
              extensions: 'php',
            },
            dir: './',
          }
        end
    end

    def php_framework
      @php_framework ||= {
        CakePHP: 'lib/Cake/Core/CakePlugin.php',
        Symfony: 'app/SymfonyRequirements.php',
      }.find do |framework, file|
        break framework if (current_dir / file).exist?
      end
    end

    def run_analyzer(options, target)
      output_file = working_dir / "phpcs-output-#{Time.now.to_i}.json"

      capture3!(
        analyzer_bin,
        '--report=json',
        "--report-json=#{output_file}",
        "-q", # Enable quiet mode. See https://github.com/squizlabs/PHP_CodeSniffer/wiki/Advanced-Usage#quieting-output
        "--runtime-set", "ignore_errors_on_exit", "1", # See https://github.com/squizlabs/PHP_CodeSniffer/wiki/Configuration-Options#ignoring-errors-when-generating-the-exit-code
        "--runtime-set", "ignore_warnings_on_exit", "1", # See https://github.com/squizlabs/PHP_CodeSniffer/wiki/Configuration-Options#ignoring-warnings-when-generating-the-exit-code
        *options,
        target
      )

      unless output_file.exist?
        return Results::Failure.new(guid: guid, analyzer: analyzer, message: "No JSON output.")
      end

      output = output_file.read
      trace_writer.message output, limit: 24_000 # Avoid timeout

      Results::Success.new(guid: guid, analyzer: analyzer).tap do |result|
        issues = []

        JSON.parse(output, symbolize_names: true)[:files].each do |path, suggests|
          suggests[:messages].each do |suggest|
            issues << Issue.new(
              path: relative_path(path.to_s),
              location: Location.new(start_line: suggest[:line]),
              id: suggest[:source],
              message: suggest[:message],
              object: {
                type: suggest[:type],
                severity: suggest[:severity],
                fixable: suggest[:fixable],
              },
              schema: Schema.issue,
            )
          end
        end

        issues.uniq { |issue| [issue.path, issue.location, issue.id, issue.message] }.each do |issue|
          result.add_issue issue
        end
      end
    end
  end
end
