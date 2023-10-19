# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Atlassian::JiraConnect::Serializers::ReviewerEntity, feature_category: :integrations do
  subject { described_class.represent(merge_request_reviewer, merge_request: merge_request) }

  let_it_be_with_reload(:merge_request) { create(:merge_request) }
  let_it_be(:reviewer) { create(:user) }
  let(:merge_request_reviewer) { build(:merge_request_reviewer, merge_request: merge_request, reviewer: reviewer) }

  describe '#to_json' do
    it { expect(subject.to_json).to be_valid_json.and match_schema('jira_connect/reviewer') }
  end

  it 'exposes all fields' do
    expect(subject.as_json.keys).to contain_exactly(:name, :email, :approvalStatus)
  end

  it 'exposes correct user\'s data' do
    expect(subject.as_json[:name]).to eq(reviewer.name)
    expect(subject.as_json[:email]).to eq(reviewer.email)
  end

  it 'exposes correct approval status' do
    expect(subject.as_json[:approvalStatus]).to eq('UNAPPROVED')
  end

  context 'with MR is reviewer, but not approved' do
    before do
      merge_request_reviewer.reviewed!
    end

    it 'exposes correct approval status' do
      expect(subject.as_json[:approvalStatus]).to eq('NEEDSWORK')
    end
  end

  context 'when MR is approved' do
    before do
      create(:approval, user: reviewer, merge_request: merge_request)
    end

    it 'exposes correct approval status' do
      expect(subject.as_json[:approvalStatus]).to eq('APPROVED')
    end
  end
end
