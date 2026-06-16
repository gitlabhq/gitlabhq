# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Issuables::MilestoneTitleResolverService, feature_category: :team_planning do
  describe '#execute' do
    let_it_be(:root_group) { create(:group) }
    let_it_be(:subgroup)   { create(:group, parent: root_group) }
    let_it_be(:project)    { create(:project, group: subgroup) }

    let_it_be(:project_milestone) { create(:milestone, title: '17.0', project: project) }
    let_it_be(:subgroup_milestone) { create(:milestone, title: '17.1', group: subgroup) }
    let_it_be(:root_group_milestone) { create(:milestone, title: '17.2', group: root_group) }

    subject(:execute) { described_class.new(container: container, title: title).execute }

    context 'when container is a project' do
      let(:container) { project }

      context 'when the title matches a project milestone' do
        let(:title) { '17.0' }

        it { is_expected.to eq(project_milestone) }
      end

      context 'when the title matches a milestone in the immediate parent group' do
        let(:title) { '17.1' }

        it { is_expected.to eq(subgroup_milestone) }
      end

      context 'when the title matches a milestone in an ancestor group' do
        let(:title) { '17.2' }

        it { is_expected.to eq(root_group_milestone) }
      end

      context 'when the title does not match any milestone in scope' do
        let(:title) { 'nonexistent' }

        it { is_expected.to be_nil }
      end

      context 'when the title is matched case-sensitively' do
        let(:title) { '17.0 ' }

        it 'strips whitespace and matches the project milestone' do
          expect(execute).to eq(project_milestone)
        end
      end

      context 'when the title differs in case' do
        let_it_be(:cased_milestone) { create(:milestone, title: 'Sprint A', project: project) }
        let(:title) { 'sprint a' }

        it 'does not match (case-sensitive)' do
          expect(execute).to be_nil
        end
      end

      context 'when the title is blank' do
        let(:title) { '' }

        it { is_expected.to be_nil }
      end

      context 'when the title is nil' do
        let(:title) { nil }

        it { is_expected.to be_nil }
      end
    end

    context 'when container is a group' do
      let(:container) { subgroup }

      context 'when the title matches a milestone in the group itself' do
        let(:title) { '17.1' }

        it { is_expected.to eq(subgroup_milestone) }
      end

      context 'when the title matches a milestone in an ancestor group' do
        let(:title) { '17.2' }

        it { is_expected.to eq(root_group_milestone) }
      end

      context 'when the title matches only a project milestone in scope' do
        let(:title) { '17.0' }

        it 'does not match (group containers do not search project milestones)' do
          expect(execute).to be_nil
        end
      end
    end

    context 'when container is neither a Project nor a Group' do
      let(:container) { Object.new }
      let(:title) { '17.0' }

      it { is_expected.to be_nil }
    end
  end
end
