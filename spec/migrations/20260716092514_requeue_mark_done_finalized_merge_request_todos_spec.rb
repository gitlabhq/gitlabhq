# frozen_string_literal: true

require 'spec_helper'
require_migration!

RSpec.describe RequeueMarkDoneFinalizedMergeRequestTodos, migration: :gitlab_main_org,
  feature_category: :notifications do
  it 'is a no-op' do
    expect { migrate! }.not_to raise_error
  end
end
