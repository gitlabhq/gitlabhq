# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Runners::UpdateRunnerService, '#execute', feature_category: :runner do
  subject(:execute) { described_class.new(current_user, runner).execute(params) }

  let(:runner) { create(:ci_runner, tag_list: %w[macos shared]) }
  let(:params) { {} }
  let(:current_user) { build_stubbed(:user) }

  before do
    allow(runner).to receive(:tick_runner_queue)
  end

  it 'does not track runner maintenance note change' do
    expect { execute }.not_to trigger_internal_events('set_runner_maintenance_note')
  end

  context 'when maintenance note is specified' do
    let(:params) { { maintenance_note: 'a note' } }

    it 'tracks runner maintenance note change' do
      expect { execute }
        .to trigger_internal_events('set_runner_maintenance_note')
        .with(user: current_user, additional_properties: { label: 'instance_type' })
    end

    context 'with group runner' do
      let_it_be(:group) { create(:group) }
      let(:runner) { create(:ci_runner, :group, groups: [group]) }

      it 'tracks runner maintenance note change' do
        expect { execute }
          .to trigger_internal_events('set_runner_maintenance_note')
          .with(user: current_user, namespace: group, additional_properties: { label: 'group_type' })
      end
    end

    context 'with project runner' do
      let_it_be(:project) { create(:project) }
      let(:runner) { create(:ci_runner, :project, projects: [project]) }

      it 'tracks runner maintenance note change' do
        expect { execute }
          .to trigger_internal_events('set_runner_maintenance_note')
          .with(user: current_user, project: project, additional_properties: { label: 'project_type' })
      end
    end
  end

  context 'with description params' do
    let(:params) { { description: 'new runner' } }

    it 'updates the runner and ticking the queue' do
      expect(execute).to be_success

      runner.reload

      expect(runner).to have_received(:tick_runner_queue)
      expect(runner.description).to eq('new runner')
    end
  end

  context 'with tag_list param' do
    using RSpec::Parameterized::TableSyntax

    where(:tag_list, :expected_tag_list) do
      [] | []
      ['macos'] | ['macos']
      ['linux'] | ['linux']
    end

    with_them do
      let(:params) { { tag_list: tag_list } }

      it 'updates the runner and ticking the queue' do
        expect(execute).to be_success

        runner.reload

        expect(runner).to have_received(:tick_runner_queue)
        expect(runner.tag_list).to eq(expected_tag_list)
      end
    end
  end

  context 'with paused param' do
    let(:params) { { paused: true } }

    it 'updates the runner and ticking the queue' do
      expect(runner.active).to be_truthy
      expect(execute).to be_success

      runner.reload

      expect(runner).to have_received(:tick_runner_queue)
      expect(runner.active).to be_falsey
    end
  end

  context 'with cost factor params' do
    let(:params) { { public_projects_minutes_cost_factor: 1.1, private_projects_minutes_cost_factor: 2.2 } }

    it 'updates the runner cost factors' do
      expect(execute).to be_success

      runner.reload

      expect(runner.public_projects_minutes_cost_factor).to eq(1.1)
      expect(runner.private_projects_minutes_cost_factor).to eq(2.2)
    end
  end

  context 'when params are not valid' do
    let(:runner) { create(:ci_runner) }
    let(:params) { { run_untagged: false } }

    it 'does not update and returns error because it is not valid' do
      expect(execute).to be_error

      runner.reload

      expect(runner).not_to have_received(:tick_runner_queue)
      expect(runner.run_untagged).to be_truthy
    end
  end
end
