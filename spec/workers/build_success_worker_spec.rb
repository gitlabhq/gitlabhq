# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildSuccessWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject { described_class.new.perform(build.id) }

    context 'when build exists' do
      context 'when the build will stop an environment' do
        let!(:build) { create(:ci_build, :stop_review_app, environment: environment.name, project: environment.project, status: :success) }
        let(:environment) { create(:environment, state: :available) }

        it 'stops the environment' do
          expect(environment).to be_available

          subject

          expect(environment.reload).to be_stopped
        end

        context 'when the build fails' do
          before do
            build.update!(status: :failed)
            environment.update!(state: :available)
          end

          it 'does not stop the environment' do
            expect(environment).to be_available

            subject

            expect(environment.reload).not_to be_stopped
          end
        end
      end
    end

    context 'when build does not exist' do
      it 'does not raise exception' do
        expect { described_class.new.perform(123) }
          .not_to raise_error
      end
    end
  end
end
