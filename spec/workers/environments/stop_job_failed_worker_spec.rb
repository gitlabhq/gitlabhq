# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::StopJobFailedWorker, feature_category: :continuous_delivery do
  describe '#perform' do
    let_it_be_with_refind(:environment) { create(:environment, state: :stopping) }

    subject { described_class.new.perform(job.id) }

    shared_examples_for 'recovering a stuck stopping environment' do
      context 'when the job is not a stop job' do
        let(:job) { non_stop_job }

        it 'does not recover the environment' do
          expect { subject }.not_to change { environment.reload.state }
        end
      end

      context 'when the stop job is not failed' do
        let(:job) { stop_job }

        before do
          job.update!(status: :success)
        end

        it 'does not recover the environment' do
          expect { subject }.not_to change { environment.reload.state }
        end
      end

      context 'when the stop job is failed' do
        let(:job) { stop_job }

        it 'recovers the environment' do
          expect { subject }
            .to change { environment.reload.state }
            .from('stopping')
            .to('available')
        end
      end

      context 'when there is no environment' do
        let(:job) { stop_job }

        before do
          environment.destroy!
        end

        it 'does not cause an error' do
          expect { subject }.not_to raise_error
        end
      end
    end

    context 'with build job' do
      let!(:stop_job) do
        create(
          :ci_build,
          :stop_review_app,
          environment: environment.name,
          project: environment.project,
          status: :failed
        )
      end

      let!(:non_stop_job) do
        create(
          :ci_build,
          :start_review_app,
          environment: environment.name,
          project: environment.project,
          status: :failed
        )
      end

      it_behaves_like 'recovering a stuck stopping environment'
    end

    context 'with bridge job' do
      let!(:stop_job) do
        create(
          :ci_bridge,
          :stop_review_app,
          environment: environment.name,
          project: environment.project,
          status: :failed
        )
      end

      let!(:non_stop_job) do
        create(
          :ci_bridge,
          :start_review_app,
          environment: environment.name,
          project: environment.project,
          status: :failed
        )
      end

      it_behaves_like 'recovering a stuck stopping environment'
    end

    context 'when job does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(non_existing_record_id) }
          .not_to raise_error
      end
    end
  end
end
