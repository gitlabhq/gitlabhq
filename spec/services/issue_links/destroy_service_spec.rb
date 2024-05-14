# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLinks::DestroyService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:project) { create(:project_empty_repo, :private) }
    let_it_be(:reporter) { create(:user, reporter_of: project) }
    let_it_be(:issue_a) { create(:issue, project: project) }
    let_it_be(:issue_b) { create(:issue, project: project) }

    let!(:issuable_link) { create(:issue_link, source: issue_a, target: issue_b) }
    let(:user) { reporter }

    subject { described_class.new(issuable_link, user).execute }

    it_behaves_like 'a destroyable issuable link'

    context 'when target is an incident' do
      let(:issue_b) { create(:incident, project: project) }

      it_behaves_like 'an incident management tracked event', :incident_management_incident_unrelate do
        let(:current_user) { reporter }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { issue_b.namespace }
        let(:category) { described_class.to_s }
        let(:action) { 'incident_management_incident_unrelate' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end
    end
  end
end
