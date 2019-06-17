# frozen_string_literal: true

require 'spec_helper'

describe JiraTrackerData do
  let(:service) { create(:jira_service, active: false, properties: {}) }

  describe 'Associations' do
    it { is_expected.to belong_to(:service) }
  end

  describe 'Validations' do
    subject { described_class.new(service: service) }

    context 'jira_issue_transition_id' do
      it { is_expected.to allow_value(nil).for(:jira_issue_transition_id) }
      it { is_expected.to allow_value('1,2,3').for(:jira_issue_transition_id) }
      it { is_expected.to allow_value('1;2;3').for(:jira_issue_transition_id) }
      it { is_expected.not_to allow_value('a,b,cd').for(:jira_issue_transition_id) }
    end

    context 'url validations' do
      context 'when service is inactive' do
        it { is_expected.not_to validate_presence_of(:url) }
        it { is_expected.not_to validate_presence_of(:username) }
        it { is_expected.not_to validate_presence_of(:password) }
      end

      context 'when service is active' do
        before do
          service.update(active: true)
        end

        it_behaves_like 'issue tracker service URL attribute', :url

        it { is_expected.to validate_presence_of(:url) }
        it { is_expected.to validate_presence_of(:username) }
        it { is_expected.to validate_presence_of(:password) }
      end
    end
  end
end
