# frozen_string_literal: true

# Extend the ProjectMember & GroupMember class with the ability to
# to run project_authorizations refresh jobs inline.

# This is needed so that calls like `group.add_member(user)` or `create(:project_member)`
# in the specs can be run without including `:sidekiq_inline` trait.
module StubbedMember
  extend ActiveSupport::Concern

  module ClearDeduplicationData
    private

    def clear_deduplication_data!
      Gitlab::Redis::Queues.with do |redis|
        redis.scan_each(match: '*duplicate*').each do |key|
          redis.del(key)
        end
      end
    end
  end

  module GroupMember
    include ClearDeduplicationData

    private

    def refresh_member_authorized_projects(blocking:)
      return super unless blocking

      # First, we remove all the keys associated with deduplication from Redis.
      # We can't perform a full flush with `Gitlab::Redis::Queues.with(&:flushdb)`
      # because that is going to remove other, unrelated enqueued jobs as well,
      # and that is going to fail some specs.
      clear_deduplication_data!

      # then we run `super`, which will enqueue a project authorizations refresh job
      super

      # then we drain (run) the jobs that were enqueued, but only for the worker class we are interested in.
      AuthorizedProjectsWorker.drain
    ensure
      clear_deduplication_data!
    end
  end

  module ProjectMember
    include ClearDeduplicationData

    private

    def refresh_member_authorized_projects(blocking:)
      return super unless blocking

      clear_deduplication_data!

      super

      AuthorizedProjectUpdate::ProjectRecalculatePerUserWorker.drain
    ensure
      clear_deduplication_data!
    end
  end
end
