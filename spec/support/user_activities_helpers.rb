module UserActivitiesHelpers
  def last_hour_members
    Gitlab::Redis.with do |redis|
      redis.zrangebyscore(user_activities_key, 1.hour.ago.to_i, Time.now.to_i)
    end
  end

  def user_score
    Gitlab::Redis.with do |redis|
      redis.zscore(user_activities_key, user.username).to_i
    end
  end

  def user_activities_key
    'user/activities'
  end
end
