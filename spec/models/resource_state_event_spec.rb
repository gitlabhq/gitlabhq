# frozen_string_literal: true

require 'spec_helper'

describe ResourceStateEvent, type: :model do
  subject { build(:resource_state_event, issue: issue) }

  let(:issue) { create(:issue) }
  let(:merge_request) { create(:merge_request) }

  it_behaves_like 'a resource event'
  it_behaves_like 'a resource event for issues'
  it_behaves_like 'a resource event for merge requests'
end
