module Millrace
  class RateLimited < StandardError
    def initialize(limit_name:, retry_after:)
      @limit_name = limit_name
      @retry_after = retry_after
    end

    attr_reader :limit_name, :retry_after
  end
end
