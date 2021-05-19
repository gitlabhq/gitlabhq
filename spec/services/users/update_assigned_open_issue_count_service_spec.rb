# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::UpdateAssignedOpenIssueCountService do
  let_it_be(:user) { create(:user) }

  describe '#initialize' do
    context 'incorrect arguments provided' do
      it 'raises an error if there are no target user' do
        expect { described_class.new(target_user: nil) }.to raise_error(ArgumentError, /Please provide a target user/)
        expect { described_class.new(target_user: "nonsense") }.to raise_error(ArgumentError, /Please provide a target user/)
      end
    end

    context 'when correct arguments provided' do
      it 'is successful' do
        expect { described_class.new(target_user: user) }.not_to raise_error
      end
    end
  end

  describe "#execute", :clean_gitlab_redis_cache do
    let(:fake_update_service) { double }
    let(:fake_issue_count_service) { double }
    let(:provided_value) { nil }

    subject { described_class.new(target_user: user).execute }

    context 'successful' do
      it 'returns a success response' do
        expect(subject).to be_success
      end

      it 'writes the cache with the new value' do
        expect(Rails.cache).to receive(:write).with(['users', user.id, 'assigned_open_issues_count'], 0, expires_in: User::COUNT_CACHE_VALIDITY_PERIOD)

        subject
      end

      it 'calls the issues finder to get the latest value' do
        expect(IssuesFinder).to receive(:new).with(user, assignee_id: user.id, state: 'opened', non_archived: true).and_return(fake_issue_count_service)
        expect(fake_issue_count_service).to receive(:execute)

        subject
      end
    end
  end
end
