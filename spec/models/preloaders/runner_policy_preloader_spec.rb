# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Preloaders::RunnerPolicyPreloader, feature_category: :fleet_visibility do
  let_it_be_with_reload(:user) { create(:user) }
  let_it_be_with_reload(:group) { create(:group, owners: [user]) }
  let_it_be_with_reload(:project) { create(:project, group: group, owners: [user]) }
  let_it_be_with_reload(:another_project) { create(:project, owners: [user]) }

  let_it_be_with_reload(:group_runner) { create(:ci_runner, :group, groups: [group]) }
  let_it_be_with_reload(:project_runner) { create(:ci_runner, :project, projects: [project, another_project]) }
  let_it_be_with_reload(:instance_runner) { create(:ci_runner, :instance) }

  let(:runners) { [group_runner, project_runner, instance_runner] }
  let(:preloader) { described_class.new(runners, user) }

  describe '#initialize' do
    it 'sets runners and current_user' do
      expect(preloader.runners).to eq(runners)
      expect(preloader.current_user).to eq(user)
    end

    it 'handles nil runners' do
      preloader = described_class.new(nil, user)
      expect(preloader.runners).to eq([])
    end
  end

  describe '#execute' do
    it 'calls ProjectPolicyPreloader with correct projects' do
      expect(::Preloaders::ProjectPolicyPreloader).to receive(:new)
                                                        .with([project, another_project], user)
                                                        .and_call_original

      preloader.execute
    end

    it 'calls GroupPolicyPreloader with correct groups' do
      expect(::Preloaders::GroupPolicyPreloader).to receive(:new)
                                                      .with([group], user)
                                                      .and_call_original

      preloader.execute
    end

    context 'when measuring queries', :request_store do
      it 'reduces N+1 queries when accessing runner associations' do
        preloader.execute

        expect do
          runners.each do |runner|
            runner.projects.each(&:route)
            runner.groups.each(&:route)
            runner.owner&.route
          end
        end.not_to exceed_query_limit(0)
      end
    end
  end

  describe '#projects' do
    it 'returns unique projects from all runners' do
      expect(preloader.send(:projects)).to contain_exactly(project, another_project)
    end

    it 'returns empty array when no runners have projects' do
      runners = [instance_runner]
      preloader = described_class.new(runners, user)

      expect(preloader.send(:projects)).to eq([])
    end

    it 'handles duplicate projects across runners' do
      shared_project = create(:project)
      runner1 = create(:ci_runner, :project, projects: [shared_project])
      runner2 = create(:ci_runner, :project, projects: [shared_project])

      preloader = described_class.new([runner1, runner2], user)

      expect(preloader.send(:projects)).to eq([shared_project])
    end
  end

  describe '#groups' do
    it 'returns unique groups from all runners' do
      expect(preloader.send(:groups)).to contain_exactly(group)
    end

    it 'returns empty array when no runners have groups' do
      runners = [project_runner, instance_runner]
      preloader = described_class.new(runners, user)

      expect(preloader.send(:groups)).to eq([])
    end

    it 'handles duplicate groups across runners' do
      shared_group = create(:group)
      runner1 = create(:ci_runner, :group, groups: [shared_group])
      runner2 = create(:ci_runner, :group, groups: [shared_group])

      preloader = described_class.new([runner1, runner2], user)

      expect(preloader.send(:groups)).to eq([shared_group])
    end
  end
end
