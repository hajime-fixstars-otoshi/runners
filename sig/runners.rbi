module Runners
end

Runners::VERSION: String

interface Runners::_Writer
  def <<: (Schema::Types::any_trace) -> void
end

class Runners::Error < StandardError
 def message: -> String
end

class Runners::UserError < Runners::Error
end

class Runners::SystemError < Runners::Error
end

class Runners::TraceWriter
  attr_reader writer: _Writer
  attr_reader sensitive_strings: Array<String>
  def initialize: (writer: _Writer, ?sensitive_strings: Array<String>) -> any

  def command_line: (Array<String>, ?recorded_at: Time) -> void
  def status: (Process::Status, ?recorded_at: Time) -> void
  def stdout: (String, ?recorded_at: Time, ?max_length: Integer) -> void
  def stderr: (String, ?recorded_at: Time, ?max_length: Integer) -> void
  def message: (String, ?recorded_at: Time, ?max_length: Integer, ?limit: Integer, ?omission: String) ?{ -> any } -> any
  def header: (String, ?recorded_at: Time) -> void
  def warning: (String, ?file: any, ?recorded_at: Time) -> void
  def ci_config: (Hash<any, any>, file: String, ?recorded_at: Time) -> void
  def error: (String, ?recorded_at: Time, ?max_length: Integer) -> void
  def <<: (Hash<Symbol, any>) -> void
  def now: -> Time
  def each_slice: (String, size: Integer) { (String, bool) -> void } -> void
  def masked_string: (String) -> String
end

class Runners::Analyzer
  attr_reader name: String
  attr_reader version: String
  def initialize: (name: String, version: String) -> any
  def valid?: () -> bool
  def as_json: () -> Hash<any, any>
end

type result = Runners::Results::Success
            | Runners::Results::Failure
            | Runners::Results::MissingFilesFailure
            | Runners::Results::Error

class Runners::Results::Base
  attr_reader guid: String
  attr_reader timestamp: Time

  def initialize: (guid: String) -> any
  def as_json: () -> Hash<any, any>
  def valid?: () -> bool
end

class Runners::Results::Success < Runners::Results::Base
  attr_reader issues: Array<Runners::Issue>
  attr_reader analyzer: Analyzer

  def initialize: (guid: String, analyzer: Analyzer) -> any
  def add_issue: (Runners::Issue) -> void
  def filter_issues: (Changes) -> void
  def add_git_blame_info: (Workspace) -> void
end

class Runners::Results::Failure < Runners::Results::Base
  attr_reader message: String
  attr_reader analyzer: Analyzer?
  def initialize: (guid: String, message: String, ?analyzer: Analyzer?) -> any
end

class Runners::Results::MissingFilesFailure < Runners::Results::Base
  attr_reader files: Array<Pathname>
  def initialize: (guid: String, files: Array<Pathname>) -> any
end

class Runners::Results::Error < Runners::Results::Base
  attr_reader exception: any
  def initialize: (guid: String, exception: any) -> any
end

class Runners::Changes
  attr_reader changed_paths: Array<Pathname>
  attr_reader unchanged_paths: Array<Pathname>
  attr_reader untracked_paths: Array<Pathname>
  attr_reader patches: GitDiffParser::Patches | nil

  def initialize: (changed_paths: Array<Pathname>,
                   unchanged_paths: Array<Pathname>,
                   untracked_paths: Array<Pathname>,
                   patches: GitDiffParser::Patches | nil) -> any
  def delete_unchanged: (dir: Pathname, ?except: Array<String>, ?only: Array<String>) { (Pathname) -> void }-> void
  def include?: (Issue) -> bool
  def self.calculate: (base_dir: Pathname, head_dir: Pathname, working_dir: Pathname, patches: GitDiffParser::Patches | nil) -> instance
end

class Runners::Processor
  attr_reader guid: String
  attr_reader workspace: Workspace
  attr_reader working_dir: Pathname
  attr_reader git_ssh_path: String
  attr_reader trace_writer: TraceWriter
  attr_reader shell: Shell
  attr_reader warnings: Array<any>
  attr_reader ci_config: any
  attr_reader ci_config_for_collect: any

  def initialize: (guid: any, workspace: Workspace, git_ssh_path: any, trace_writer: TraceWriter) -> any
  def relative_path: (String, ?from: Pathname) -> Pathname
  def setup: () { -> result } -> result
  def analyze: (Changes) -> result
  def ci_config_path: () -> Pathname
  def ci_config_path_name: () -> String
  def ci_section: (?Hash<any, any>) -> Hash<any, any>
  def ci_section_root_dir: () -> String?
  def check_root_dir_exist: () -> result?
  def push_root_dir: <'x> { -> 'x } -> 'x
  def ensure_files: (*Pathname) { (Pathname) -> result } -> result
  def ensure_runner_config_schema: <'x> (any) { ('x) -> result } -> result
  def push_dir: <'x> (Pathname) { -> 'x } -> 'x
  def current_dir: () -> Pathname

  def capture3: (String, *String, **capture3_options) -> [String, String, Process::Status]
  def capture3!: (String, *String, **capture3_options) -> [String, String]
  def capture3_with_retry!: (String, *String, ?tries: Integer) -> [String, String]
  def capture3_trace: (String, *String, **capture3_options) -> [String, String, Process::Status]

  def push_env_hash: <'x> (Hash<String, String?>) { -> 'x } -> 'x
  def env_hash: -> Hash<String, String?>

  def delete_unchanged_files: (Changes, ?except: Array<String>, ?only: Array<String>) -> void
  def add_warning: (String, ?file: String?) -> void
  def add_warning_if_deprecated_version: (minimum: String, ?file: String?, ?deadline: Time?) -> void
  def add_warning_if_deprecated_options: (Array<Symbol>, doc: String) -> void
  def self.ci_config_section_name: () -> String
  def analyzer: -> Analyzer
  def analyzer_name: -> String
  def analyzer_bin: -> String
  def analyzer_version: -> String
  def extract_version!: (String | Array<String>, ?(String | Array<String>), ?pattern: Regexp) -> String
  def build_field_reference_from_path: (StrongJSON::Type::ErrorPath | String) -> String
  def root_dir: -> Pathname
  def directory_traversal_attack?: (String) -> bool
  def show_runtime_versions: -> void
  def git_blame_info: (String, Integer, Integer) -> Array<GitBlameInfo>
end

type capture3_options = bool | Proc

class Runners::Shell
  attr_reader trace_writer: TraceWriter
  attr_reader env_hash_stack: Array<Hash<String, String?>>
  attr_reader dir_stack: Array<Pathname>

  def initialize: (current_dir: Pathname, env_hash: Hash<String, String?>, trace_writer: TraceWriter) -> any

  def capture3: (String, *String, **capture3_options) -> [String, String, Process::Status]
  def capture3!: (String, *String, **capture3_options) -> [String, String]
  def capture3_with_retry!: (String, *String, ?tries: Integer) -> [String, String]
  def capture3_trace: (String, *String, **capture3_options) -> [String, String, Process::Status]

  def push_dir: <'x> (Pathname) { -> 'x } -> 'x
  def current_dir: () -> Pathname

  def push_env_hash: <'x> (Hash<String, String?>) { -> 'x } -> 'x
  def env_hash: -> Hash<String, String?>
end

class Runners::Shell::ExecError < Runners::SystemError
  attr_reader type: Symbol
  attr_reader args: Array<String>
  attr_reader stdout_str: String
  attr_reader stderr_str: String
  attr_reader status: Process::Status
  attr_reader dir: Pathname

  def initialize: (type: Symbol, args: Array<String>, stdout_str: String, stderr_str: String, status: Process::Status, dir: Pathname) -> any
end

class Runners::Harness
  attr_reader guid: String
  attr_reader processor_class: Processor.class constructor
  attr_reader options: Options
  attr_reader working_dir: Pathname
  attr_reader trace_writer: TraceWriter
  attr_reader warnings: Array<String>
  attr_reader ci_config: any

  def initialize: (guid: String, processor_class: Processor.class constructor, options: Options, working_dir: Pathname, trace_writer: TraceWriter) -> any
  def run: () -> result
  def ensure_result: { -> result } -> result
  def handle_error: (Exception) -> void
end

class Runners::Harness::InvalidResult < StandardError
  attr_reader result: result
  def initialize: (result: result) -> any
end

class Runners::CLI
  attr_reader stdout: ::IO
  attr_reader stderr: ::IO
  attr_reader guid: String
  attr_reader analyzer: String
  attr_reader options: Runners::Options

  def initialize: (argv: Array<String>, stdout: ::IO, stderr: ::IO) -> any

  def with_working_dir: <'x> { (Pathname) -> 'x } -> 'x
  def processor_class: () -> Processor.class
  def validate_analyzer!: () -> void
  def run: () -> result
  def io: () -> Runners::IO
  def sensitive_strings: () -> Array<String>
end
