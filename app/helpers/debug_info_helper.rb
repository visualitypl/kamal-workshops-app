module DebugInfoHelper
  def server_hostname
    @hostname ||= `hostname`.strip
  end

  def ip_address
    @ip_address ||= `hostname -i | awk '{print $3}'`.split.first || "unknown"
  end

  def kamal_version
    @kamal_version ||= ENV["KAMAL_VERSION"] || "unknown"
  end
end
