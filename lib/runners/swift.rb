module Runners
  module Swift
    def show_runtime_versions
      capture3! "swift", "--version"
    end
  end
end
