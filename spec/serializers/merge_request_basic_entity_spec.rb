# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestBasicEntity do
  let(:resource) { build(:merge_request, params) }
  let(:params) { {} }

  subject do
    described_class.new(resource).as_json
  end

  it 'has public_merge_status as merge_status' do
    expect(resource).to receive(:public_merge_status).and_return('checking')

    expect(subject[:merge_status]).to eq 'checking'
  end

  describe '#reviewers' do
    let(:params) { { reviewers: [reviewer] } }
    let(:reviewer) { build(:user) }

    context 'when merge_request_reviewers feature is disabled' do
      it 'does not contain assignees attributes' do
        stub_feature_flags(merge_request_reviewers: false)

        expect(subject[:reviewers]).to be_nil
      end
    end

    context 'when merge_request_reviewers feature is enabled' do
      it 'contains reviewers attributes' do
        stub_feature_flags(merge_request_reviewers: true)

        expect(subject[:reviewers].count).to be 1
        expect(subject[:reviewers].first.keys).to include(
          :id, :name, :username, :state, :avatar_url, :web_url
        )
      end
    end
  end
end
