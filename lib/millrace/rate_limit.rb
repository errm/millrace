require "digest"
require "prorate"

module Millrace
  class RateLimit
    def initialize(name:, rate:, window:, penalty: 0, redis_config: nil)
      @name         = name
      @rate         = rate
      @window       = window
      @penalty      = penalty
      @redis_config = redis_config
    end

    attr_reader :name, :rate, :window

    def before(controller)
      bucket = get_bucket(controller.request.remote_ip)
      level = bucket.fillup(1).level

      return if level < threshold

      if level - 1 < threshold
        level = bucket.fillup(penalty).level
      end

      raise RateLimited.new(limit_name: name, retry_after: retry_after(level))
    end

    private

      def retry_after(level)
        ((level - threshold) / rate).to_i
      end

      def get_bucket(ip)
        Prorate::LeakyBucket.new(
          redis: redis,
          redis_key_prefix: key(ip),
          leak_rate: rate,
          bucket_capacity: capacity,
        )
      end

      def key(ip)
        "millrace.#{name}.#{Digest::SHA1.hexdigest(ip)}"
      end

      def capacity
        (threshold * 2) + penalty
      end

      def threshold
        window * rate
      end

      def penalty
        @penalty * rate
      end

      def redis_config
        @redis_config || { url: ENV.fetch("MILLRACE_REDIS_URL", nil) }.compact
      end

      def redis
        Thread.current["millrace_#{name}_redis"] ||= Redis.new(redis_config)
      end
  end
end
