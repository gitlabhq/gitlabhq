require 'spec_helper'

describe MergeRequest::Metrics do
  subject { described_class.new }

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request) }
    it { is_expected.to belong_to(:latest_closed_by).class_name('User') }
    it { is_expected.to belong_to(:merged_by).class_name('User') }
  end
end
