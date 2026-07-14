# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueLinks::CreateService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:user) { create :user }
    let_it_be(:namespace) { create :namespace }
    let_it_be_with_reload(:project) { create :project, namespace: namespace, guests: user }
    let_it_be_with_reload(:issuable) { create :issue, project: project }
    let_it_be(:issuable2) { create :issue, project: project }
    let_it_be(:restricted_issuable) { create :issue }
    let_it_be(:public_project) { create :project, :public }
    let_it_be(:readonly_issuable) { create :issue, project: public_project }
    let_it_be(:another_project) { create :project, namespace: project.namespace, guests: user }
    let_it_be(:issuable3) { create :issue, project: another_project }
    let_it_be(:issuable_a) { create :issue, project: project }
    let_it_be(:issuable_b) { create :issue, project: project }
    let_it_be(:issuable_link) { create :issue_link, source: issuable, target: issuable_b, link_type: IssueLink::TYPE_RELATES_TO }

    let(:issuable_parent) { issuable.project }
    let(:issuable_type) { :issue }
    let(:issuable_link_class) { IssueLink }
    let(:params) { {} }

    it_behaves_like 'issuable link creation'

    context 'when the target is in a different organization' do
      let_it_be(:other_organization) { create(:organization) }
      let_it_be(:other_group) { create(:group, organization: other_organization) }
      let_it_be(:other_project) { create(:project, :public, group: other_group) }
      let_it_be(:cross_org_issuable) { create(:issue, project: other_project) }

      let(:params) { { issuable_references: [cross_org_issuable.to_reference(full: true)] } }

      subject(:result) { described_class.new(issuable, user, params).execute }

      before do
        other_project.add_guest(user)
      end

      it 'does not create the link and returns an error' do
        expect { result }.not_to change { IssueLink.count }
        expect(result[:status]).to eq(:error)
        expect(result[:message]).to include('belongs to a different organization')
      end

      context 'when the prevent_cross_organization_work_item_actions flag is disabled' do
        before do
          stub_feature_flags(prevent_cross_organization_work_item_actions: false)
        end

        it 'creates the link' do
          expect { result }.to change { IssueLink.count }.by(1)
          expect(result[:status]).to eq(:success)
        end
      end
    end

    context 'when target is an incident' do
      let_it_be_with_reload(:issue) { create(:incident, project: project) }

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
