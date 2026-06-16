# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLinks::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user, freeze: false) { create :user }
    let_it_be(:namespace, freeze: false) { create :namespace }
    let_it_be(:project, freeze: false) { create :project, namespace: namespace }
    let_it_be(:issuable, freeze: false) { create :issue, project: project }
    let_it_be(:issuable2, freeze: false) { create :issue, project: project }
    let_it_be(:restricted_issuable, freeze: false) { create :issue }
    let_it_be(:another_project, freeze: false) { create :project, namespace: project.namespace }
    let_it_be(:issuable3, freeze: false) { create :issue, project: another_project }
    let_it_be(:issuable_a, freeze: false) { create :issue, project: project }
    let_it_be(:issuable_b, freeze: false) { create :issue, project: project }
    let_it_be(:issuable_link, freeze: false) { create :issue_link, source: issuable, target: issuable_b, link_type: IssueLink::TYPE_RELATES_TO }

    let(:issuable_parent) { issuable.project }
    let(:issuable_type) { :issue }
    let(:issuable_link_class) { IssueLink }
    let(:params) { {} }

    before do
      project.add_guest(user)
      another_project.add_guest(user)
    end

    it_behaves_like 'issuable link creation'

    context 'when target is an incident' do
      let_it_be(:issue, freeze: false) { create(:incident, project: project) }

      let(:params) do
        { issuable_references: [issuable2.to_reference, issuable3.to_reference(another_project)] }
      end

      subject { described_class.new(issue, user, params).execute }

      it_behaves_like 'an incident management tracked event', :incident_management_incident_relate do
        let(:current_user) { user }
      end

      it_behaves_like 'Snowplow event tracking with RedisHLL context' do
        let(:namespace) { issue.namespace }
        let(:category) { described_class.to_s }
        let(:action) { 'incident_management_incident_relate' }
        let(:label) { 'redis_hll_counters.incident_management.incident_management_total_unique_counts_monthly' }
      end
    end
  end
end
