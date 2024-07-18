class ApplicationController < ActionController::Base
  helper_method :redis_info

  private

  def redis_info
    @redis_info ||= Sidekiq.redis(&:info)
  rescue RedisClient::CannotConnectError
    nil
  end
end
