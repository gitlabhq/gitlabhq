# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ImportCsv::PreprocessMilestonesService, feature_category: :importers do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user) }
  let_it_be(:provided_titles) { %w[15.10 10.1] }

  let(:service) { described_class.new(user, project, provided_titles) }

  subject { service.execute }

  describe '#execute' do
    let(:project_milestones) { ::MilestonesFinder.new({ project_ids: [project.id] }).execute }

    shared_examples 'csv import' do |is_success:, milestone_errors:|
      it 'does not create milestones' do
        expect { subject }.not_to change { project_milestones.count }
      end

      it 'reports any missing milestones' do
        result = subject

        if is_success
          expect(result).to be_success
        else
          expect(result[:status]).to eq(:error)
          expect(result.payload).to match(milestone_errors)
        end
      end
    end

    context 'with csv that has missing or unavailable milestones' do
      it_behaves_like 'csv import',
        { is_success: false, milestone_errors: { missing: { header: 'Milestone', titles: %w[15.10 10.1] } } }
    end

    context 'with csv that includes project milestones' do
      let!(:project_milestone) { create(:milestone, project: project, title: '15.10') }

      it_behaves_like 'csv import',
        { is_success: false, milestone_errors: { missing: { header: 'Milestone', titles: ["10.1"] } } }
    end

    context 'with csv that includes milestones column' do
      let!(:project_milestone) { create(:milestone, project: project, title: '15.10') }

      context 'when milestones exist in the importing projects group' do
        let!(:group_milestone) { create(:milestone, group: group, title: '10.1') }

        it_behaves_like 'csv import', { is_success: true, milestone_errors: nil }
      end

      context 'when milestones exist in a subgroup of the importing projects group' do
        let_it_be(:subgroup) { create(:group, parent: group) }
        let!(:group_milestone) { create(:milestone, group: subgroup, title: '10.1') }

        it_behaves_like 'csv import',
          { is_success: false, milestone_errors: { missing: { header: 'Milestone', titles: ["10.1"] } } }
      end

      context 'when milestones exist in a different project from the importing project' do
        let_it_be(:second_project) { create(:project, group: group) }
        let!(:second_project_milestone) { create(:milestone, project: second_project, title: '10.1') }

        it_behaves_like 'csv import',
          { is_success: false, milestone_errors: { missing: { header: 'Milestone', titles: ["10.1"] } } }
      end

      context 'when duplicate milestones exist in the projects group and parent group' do
        let_it_be(:sub_group) { create(:group, parent: group) }
        let_it_be(:project) { create(:project, group: sub_group) }
        let!(:ancestor_group_milestone) do
          build(:milestone, group: group, title: '15.10').tap do |record|
            record.save!(validate: false)
          end
        end

        let!(:ancestor_group_milestone_two) { create(:milestone, group: group, title: '10.1') }
        let!(:group_milestone) do
          build(:milestone, group: sub_group, title: '10.1').tap do |record|
            record.save!(validate: false)
          end
        end

        it_behaves_like 'csv import', { is_success: true, milestone_errors: nil }
      end
    end
  end
end
