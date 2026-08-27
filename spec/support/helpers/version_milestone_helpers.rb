# frozen_string_literal: true

module VersionMilestoneHelpers
  def previous_milestone(current)
    if current.minor > 0
      Gitlab::VersionInfo.new(current.major, current.minor - 1, 0)
    else
      Gitlab::VersionInfo.new(current.major - 1, 11, 0)
    end
  end
end
