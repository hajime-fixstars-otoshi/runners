module Runners
  module Java
    def show_runtime_versions
      capture3! "java", "-version"
      capture3! "mvn", "--version"
    end
  end
end
