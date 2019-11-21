module Runners
  class Error < StandardError; end
  class UserError < Error; end
  class SystemError < Error; end
end
