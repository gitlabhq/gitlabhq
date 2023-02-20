# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Custom URLs', 'milestone', feature_category: :team_planning do
  describe 'milestone' do
    context 'with project' do
      let(:project) { milestone.project }
      let(:milestone) { build_stubbed(:milestone, :on_project) }

      it 'creates directs' do
        expect(milestone_path(milestone)).to eq(project_milestone_path(project, milestone))
        expect(milestone_url(milestone)).to eq(project_milestone_url(project, milestone))
      end
    end

    context 'with group' do
      let(:group) { milestone.group }
      let(:milestone) { build_stubbed(:milestone, :on_group) }

      it 'creates directs' do
        expect(milestone_path(milestone)).to eq(group_milestone_path(group, milestone))
        expect(milestone_url(milestone)).to eq(group_milestone_url(group, milestone))
      end
    end
  end
end
