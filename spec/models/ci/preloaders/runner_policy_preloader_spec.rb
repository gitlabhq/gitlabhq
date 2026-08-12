# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Preloaders::RunnerPolicyPreloader, feature_category: :fleet_visibility do
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
    it 'calls ProjectPolicyPreloader with runner projects and owner projects' do
      expect(::Preloaders::ProjectPolicyPreloader).to receive(:new)
                                                        .with([project, another_project], user)
                                                        .and_call_original
      expect(::Preloaders::ProjectPolicyPreloader).to receive(:new)
                                                        .with([project], user)
                                                        .and_call_original

      preloader.execute
    end

    it 'calls GroupPolicyPreloader with runner groups and owner groups' do
      expect(::Preloaders::GroupPolicyPreloader).to receive(:new)
                                                      .with([group], user)
                                                      .twice
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

  describe '#owner_projects' do
    subject(:owner_projects) { preloader.send(:owner_projects) }

    it 'returns unique owner projects from all runners' do
      expect(owner_projects).to contain_exactly(project)
    end

    context 'when no runners have an owner project' do
      let(:runners) { [group_runner, instance_runner] }

      it { is_expected.to eq([]) }
    end

    context 'with runners from the same project' do
      let_it_be(:shared_project) { create(:project) }

      let(:runners) { create_list(:ci_runner, 2, :project, projects: [shared_project]) }

      it 'handles duplicate owner projects across runners' do
        expect(owner_projects).to contain_exactly(shared_project)
      end
    end
  end

  describe '#owner_groups' do
    subject(:owner_groups) { preloader.send(:owner_groups) }

    it 'returns unique owner groups from all runners' do
      expect(owner_groups).to contain_exactly(group)
    end

    context 'when no runners have an owner group' do
      let(:runners) { [project_runner, instance_runner] }

      it { is_expected.to eq([]) }
    end

    context 'with runners from the same group' do
      let_it_be(:shared_group) { create(:group) }

      let(:runners) { create_list(:ci_runner, 2, :group, groups: [shared_group]) }

      it 'handles duplicate owner groups across runners' do
        expect(owner_groups).to contain_exactly(shared_group)
      end
    end
  end
end
