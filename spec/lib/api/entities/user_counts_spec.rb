# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::UserCounts do
  let(:user) { build(:user) }

  subject(:entity) { described_class.new(user).as_json }

  it 'represents user counts', :aggregate_failures do
    expect(user).to receive(:assigned_open_merge_requests_count).and_return(1).twice
    expect(user).to receive(:assigned_open_issues_count).and_return(2).once
    expect(user).to receive(:review_requested_open_merge_requests_count).and_return(3).once
    expect(user).to receive(:todos_pending_count).and_return(4).once

    expect(entity).to include(
      merge_requests: 1,
      assigned_issues: 2,
      assigned_merge_requests: 1,
      review_requested_merge_requests: 3,
      todos: 4
    )
  end
end
