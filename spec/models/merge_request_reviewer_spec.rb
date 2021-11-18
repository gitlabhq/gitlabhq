# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestReviewer do
  let(:merge_request) { create(:merge_request) }

  subject { merge_request.merge_request_reviewers.build(reviewer: create(:user)) }

  it_behaves_like 'having unique enum values'

  it_behaves_like 'having reviewer state'

  describe 'associations' do
    it { is_expected.to belong_to(:merge_request).class_name('MergeRequest') }
    it { is_expected.to belong_to(:reviewer).class_name('User').inverse_of(:merge_request_reviewers) }
  end
end
