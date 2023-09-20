# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Environments::StopJobSuccessWorker, feature_category: :continuous_delivery do
  describe '#perform' do
    let_it_be_with_refind(:environment) { create(:environment, state: :available) }

    subject { described_class.new.perform(job.id) }

    shared_examples_for 'stopping an associated environment' do
      it 'stops the environment' do
        expect(environment).to be_available

        subject

        expect(environment.reload).to be_stopped
      end

      context 'when the job fails' do
        before do
          job.update!(status: :failed)
          environment.update!(state: :available)
        end

        it 'does not stop the environment' do
          expect(environment).to be_available

          subject

          expect(environment.reload).not_to be_stopped
        end
      end
    end

    context 'with build job' do
      let!(:job) do
        create(:ci_build, :stop_review_app, environment: environment.name, project: environment.project,
          status: :success)
      end

      it_behaves_like 'stopping an associated environment'
    end

    context 'with bridge job' do
      let!(:job) do
        create(:ci_bridge, :stop_review_app, environment: environment.name, project: environment.project,
          status: :success)
      end

      it_behaves_like 'stopping an associated environment'
    end

    context 'when job does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
