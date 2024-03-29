module Runners
  module Schema
    Issue = _ = StrongJSON.new do
      # @type self: Types::Issue

      let :location, enum?(object(start_line: integer, start_column: integer, end_line: integer, end_column: integer),
                           object(start_line: integer, end_line: integer),
                           object(start_line: integer))

      let :git_blame_info, object(commit: string, line_hash: string, original_line: integer, final_line: integer)

      let :issue, object(path: string, location: location, id: string, message: string, links: array(string), object: any, git_blame_info: optional(git_blame_info))
    end

    Result = _ = StrongJSON.new do
      # @type self: Types::Result

      let :warning, object(message: string, file: string?)
      let :analyzer, object(name: string, version: string)

      let :success, object(guid: string, timestamp: string, type: literal("success"), issues: array(Issue.issue), analyzer: analyzer)
      let :failure, object(guid: string, timestamp: string, type: literal("failure"), message: string, analyzer: optional(analyzer))
      let :missing_file_failure, object(guid: string, timestamp: string, type: literal("missing_files"), files: array(string))
      let :error, object(guid: string, timestamp: string, type: literal("error"), class: string, backtrace: array(string), inspect: string)

      let :envelope, object(
        result: enum(success, failure, missing_file_failure, error),
        warnings: array(warning),
        ci_config: any?,
        version: string,
      )
    end
  end
end
