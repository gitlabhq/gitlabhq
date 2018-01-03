module UserActivitiesHelpers
  def user_activity(user)
    Gitlab::UserActivities.new
      .find { |k, _| k == user.id.to_s }&.
      second
  end
end
