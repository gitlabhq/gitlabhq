# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Ci::Runners::BulkPauseRunnersService, '#execute', feature_category: :fleet_visibility do
  subject(:execute) { described_class.new(**service_args).execute }

  let_it_be(:project1) { create(:project) }

  let_it_be(:admin) { create(:admin) }
  let_it_be(:maintainer) { create(:user, maintainer_of: project1) }
  let_it_be(:user) { create(:user) }

  let_it_be(:instance_runners_active) { create_list(:ci_runner, 2) }
  let_it_be(:instance_runners_paused) { create_list(:ci_runner, 2, :paused) }
  let_it_be(:project_runners_active) { create_list(:ci_runner, 2, :project, projects: [project1]) }

  let(:service_args) do
    {
      runners: target_runners,
      current_user: current_user,
      paused: paused
    }
  end

  context 'without target_runners' do
    let(:target_runners) { nil }
    let(:paused) { false }
    let(:current_user) { admin }

    it 'return 0 paused runners' do
      expect(execute).to be_success
      expect(execute.payload).to eq(updated_count: 0, updated_runners: [], errors: [])
    end
  end

  context 'with admin right', :enable_admin_mode do
    let(:current_user) { admin }

    context 'when targeting instance runners' do
      let(:target_runners) { Ci::Runner.instance_type }

      context 'when activating paused runners' do
        let(:target_runners) { Ci::Runner.instance_type.paused }
        let(:paused) { false }

        it 'unpauses runners' do
          expect(execute).to be_success
          expect(execute.payload[:updated_count]).to eq 2
          expect(execute.payload[:errors]).to be_empty
          expect(execute.payload[:updated_runners]).to all(be_active)
        end
      end

      context 'when pausing active runners' do
        let(:target_runners) { Ci::Runner.instance_type.active }
        let(:paused) { true }

        it 'pauses runners' do
          expect(execute).to be_success
          expect(execute.payload[:updated_count]).to eq 2
          expect(execute.payload[:errors]).to be_empty
          expect(execute.payload[:updated_runners]).not_to include(be_active)
        end

        context 'with too many runners specified' do
          before do
            stub_const("#{described_class}::RUNNER_LIMIT", 1)
          end

          it 'only pauses first runner' do
            expect(execute).to be_success
            expect(execute.payload[:updated_count]).to eq 1
            expect(execute.payload[:updated_runners]).not_to include(be_active)
            expect(target_runners.map(&:id)).to include(execute.payload[:updated_runners].first.id)
          end
        end
      end

      context 'when pausing mixed-state runners' do
        let(:target_runners) { Ci::Runner.instance_type }
        let(:paused) { true }

        it 'pauses runners' do
          expect(execute).to be_success
          expect(execute.payload[:updated_count]).to eq 4
          expect(execute.payload[:errors]).to be_empty
          expect(execute.payload[:updated_runners]).not_to include(be_active)
        end
      end
    end
  end

  context 'when user is maintainer' do
    let(:current_user) { maintainer }

    context 'when activating mixed-state instance runners' do
      let(:target_runners) { Ci::Runner.instance_type }
      let(:paused) { false }

      it 'returns errors' do
        expect(execute).to be_success
        expect(execute.payload[:updated_count]).to eq 0
        expect(execute.payload[:errors].first).to include "User does not have permission to update / pause"
        expect(execute.payload[:updated_runners]).to be_empty
      end
    end

    context 'when pausing active project runners' do
      let(:target_runners) { Ci::Runner.project_type.active }
      let(:paused) { true }

      it 'pauses the runners' do
        expect(execute).to be_success
        expect(execute.payload[:updated_count]).to eq 2
        expect(execute.payload[:errors]).to be_empty
        expect(execute.payload[:updated_runners]).not_to include(be_active)
      end
    end
  end

  context 'when user is not member' do
    let(:current_user) { user }

    context 'when pausing active project runners' do
      let(:target_runners) { Ci::Runner.project_type.active }
      let(:paused) { true }

      it 'returns errors' do
        expect(execute).to be_success
        expect(execute.payload[:updated_count]).to eq 0
        expect(execute.payload[:errors].first).to include "User does not have permission to update / pause"
        expect(execute.payload[:updated_runners]).to be_empty
      end
    end
  end

  context 'when user has permissions on only some runners' do
    let(:current_user) { maintainer }

    context 'when pausing active runners' do
      let(:target_runners) { Ci::Runner.active }
      let(:paused) { true }

      it 'returns errors' do
        expect(execute).to be_success
        expect(execute.payload[:updated_count]).to eq 2
        expect(execute.payload[:errors].first).to include "User does not have permission to update / pause runner(s)"
        expect(execute.payload[:updated_runners]).not_to include(be_active)
        expect(execute.payload[:updated_runners]).to match_array(project_runners_active)
      end
    end
  end
end
