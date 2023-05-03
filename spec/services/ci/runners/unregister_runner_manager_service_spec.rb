# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::UnregisterRunnerManagerService, '#execute', feature_category: :runner_fleet do
  subject(:execute) { described_class.new(runner, 'some_token', system_id: system_id).execute }

  context 'with runner registered with registration token' do
    let!(:runner) { create(:ci_runner, registration_type: :registration_token) }
    let(:system_id) { nil }

    it 'does not destroy runner or runner managers' do
      expect do
        expect(execute).to be_error
      end.to not_change { Ci::Runner.count }
         .and not_change { Ci::RunnerManager.count }
      expect(runner[:errors]).to be_nil
    end
  end

  context 'with runner created in UI' do
    let!(:runner_manager1) { create(:ci_runner_machine, runner: runner, system_xid: 'system_id_1') }
    let!(:runner_manager2) { create(:ci_runner_machine, runner: runner, system_xid: 'system_id_2') }
    let!(:runner) { create(:ci_runner, registration_type: :authenticated_user) }

    context 'with system_id specified' do
      let(:system_id) { runner_manager1.system_xid }

      it 'destroys runner_manager1 and leaves runner', :aggregate_failures do
        expect do
          expect(execute).to be_success
        end.to change { Ci::RunnerManager.count }.by(-1)
           .and not_change { Ci::Runner.count }
        expect(runner[:errors]).to be_nil
        expect(runner.runner_managers).to contain_exactly(runner_manager2)
      end
    end

    context 'with unknown system_id' do
      let(:system_id) { 'unknown_system_id' }

      it 'raises RecordNotFound error', :aggregate_failures do
        expect do
          execute
        end.to raise_error(ActiveRecord::RecordNotFound)
           .and not_change { Ci::Runner.count }
           .and not_change { Ci::RunnerManager.count }
      end
    end

    context 'with system_id missing' do
      let(:system_id) { nil }

      it 'returns error and leaves runner_manager1', :aggregate_failures do
        expect do
          expect(execute).to be_error
          expect(execute.message).to eq('`system_id` needs to be specified for runners created in the UI.')
        end.to not_change { Ci::Runner.count }
           .and not_change { Ci::RunnerManager.count }
      end
    end
  end
end
