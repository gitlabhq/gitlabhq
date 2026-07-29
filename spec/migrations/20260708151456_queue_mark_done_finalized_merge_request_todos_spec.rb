# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe QueueMarkDoneFinalizedMergeRequestTodos, migration: :gitlab_main_org,
  feature_category: :notifications do
  # This migration was no-oped and re-queued as
  # RequeueMarkDoneFinalizedMergeRequestTodos after the original batch sizes
  # caused statement timeouts on GitLab.com.
  it 'is a no-op' do
    expect { migrate! }.not_to raise_error
  end
end
