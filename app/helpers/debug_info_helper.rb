module DebugInfoHelper
  def server_hostname
    @hostname ||= `hostname`.strip
  end

  def kamal_version
    @kamal_version ||= ENV["KAMAL_VERSION"] || "unknown"
  end

  def redis_info
    @redis_info ||= Sidekiq.redis(&:info)
  rescue RedisClient::CannotConnectError
    nil
  end
end
