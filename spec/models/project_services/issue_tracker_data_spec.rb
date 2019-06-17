# frozen_string_literal: true

require 'spec_helper'

describe IssueTrackerData do
  let(:service) { create(:custom_issue_tracker_service, active: false, properties: {}) }

  describe 'Associations' do
    it { is_expected.to belong_to :service }
  end

  describe 'Validations' do
    subject { described_class.new(service: service) }

    context 'url validations' do
      context 'when service is inactive' do
        it { is_expected.not_to validate_presence_of(:project_url) }
        it { is_expected.not_to validate_presence_of(:issues_url) }
      end

      context 'when service is active' do
        before do
          service.update(active: true)
        end

        it_behaves_like 'issue tracker service URL attribute', :project_url
        it_behaves_like 'issue tracker service URL attribute', :issues_url
        it_behaves_like 'issue tracker service URL attribute', :new_issue_url

        it { is_expected.to validate_presence_of(:project_url) }
        it { is_expected.to validate_presence_of(:issues_url) }
      end
    end
  end
end
