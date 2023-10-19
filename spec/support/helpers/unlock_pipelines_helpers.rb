# frozen_string_literal: true

module UnlockPipelinesHelpers
  def pipeline_ids_waiting_to_be_unlocked
    Ci::UnlockPipelineRequest.with_redis do |redis|
      redis.zrange(Ci::UnlockPipelineRequest::QUEUE_REDIS_KEY, 0, -1).map(&:to_i)
    end
  end

  def expect_to_have_pending_unlock_pipeline_request(pipeline_id, timestamp)
    Ci::UnlockPipelineRequest.with_redis do |redis|
      timestamp_stored = redis.zscore(Ci::UnlockPipelineRequest::QUEUE_REDIS_KEY, pipeline_id)
      expect(timestamp_stored).not_to be_nil
      expect(timestamp_stored.to_i).to eq(timestamp)
    end
  end

  def timestamp_of_pending_unlock_pipeline_request(pipeline_id)
    Ci::UnlockPipelineRequest.with_redis do |redis|
      redis.zscore(Ci::UnlockPipelineRequest::QUEUE_REDIS_KEY, pipeline_id).to_i
    end
  end
end
