# frozen_string_literal: true

require 'spec_helper'

describe MergeRequest::Metrics do
  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:latest_closed_by).class_name('User') }
    it { is_expected.to belong_to(:merged_by).class_name('User') }
  end
end
