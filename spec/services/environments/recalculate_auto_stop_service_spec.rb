# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::RecalculateAutoStopService, feature_category: :environment_management do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }

  let(:service) { described_class.new(deployable) }

  describe '#execute' do
    let(:environment) { create(:environment, project: project, name: 'example-env') }
    let(:deployable) { create(:ci_build, environment: environment.name, options: options, pipeline: pipeline) }

    let(:auto_stop_in) { '1 day' }
    let(:options) do
      {
        script: 'deploy',
        environment: {
          name: environment.name,
          action: environment_action,
          auto_stop_in: auto_stop_in
        }
      }
    end

    subject(:recalculate) { service.execute }

    shared_examples 'recalculating auto stop at' do |can_reset_timer|
      it 'updates the environment auto_stop_at' do
        expected_stop_at = be_like_time(1.day.from_now)

        expect { recalculate }.to change { environment.reload.auto_stop_at }.from(nil).to(expected_stop_at)
      end

      context 'when the environment no longer exists' do
        before do
          environment.delete
        end

        it 'does not raise an error' do
          expect { recalculate }.not_to raise_error
        end
      end

      context 'when auto_stop_in is not specified' do
        let(:auto_stop_in) { nil }

        it 'does not update the environment' do
          expect { recalculate }.not_to change { environment.reload.auto_stop_at }
        end

        context 'when there is a previous successful deployment' do
          let!(:previous_deployable) { create(:ci_build, options: previous_deployable_options, project: project) }
          let!(:deployment) { create(:deployment, :success, deployable: previous_deployable, environment: environment) }

          let(:previous_deployable_options) do
            {
              script: 'deploy',
              environment: {
                name: environment.name,
                auto_stop_in: previous_auto_stop_in
              }
            }
          end

          context 'and the deployment job set auto_stop_in' do
            let(:previous_auto_stop_in) { '1 month' }

            if can_reset_timer
              it 'updates the environment auto_stop_at' do
                expected_stop_at = be_like_time(
                  ::Gitlab::Ci::Build::DurationParser
                    .new(previous_auto_stop_in)
                    .seconds_from_now
                )

                expect { recalculate }.to change { environment.reload.auto_stop_at }.from(nil).to(expected_stop_at)
              end
            else
              it 'does not update the environment' do
                expect { recalculate }.not_to change { environment.reload.auto_stop_at }
              end
            end
          end

          context 'and the deployment job did not set auto_stop_in' do
            let(:previous_auto_stop_in) { nil }

            it 'does not update the environment' do
              expect { recalculate }.not_to change { environment.reload.auto_stop_at }
            end
          end
        end
      end
    end

    context 'with environment action: prepare' do
      let(:environment_action) { 'prepare' }

      include_examples 'recalculating auto stop at', true
    end

    context 'with environment action: access' do
      let(:environment_action) { 'access' }

      include_examples 'recalculating auto stop at', true
    end

    context 'with environment action: verify' do
      let(:environment_action) { 'verify' }

      include_examples 'recalculating auto stop at', false
    end

    context 'with environment action: start' do
      let(:environment_action) { 'start' }

      it 'does not update the environment' do
        expect { recalculate }.not_to change { environment.reload.auto_stop_at }
      end
    end
  end
end
