# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BuildSuccessWorker do
  describe '#perform' do
    subject { described_class.new.perform(build.id) }

    context 'when build exists' do
      context 'when the build will stop an environment' do
        let!(:build) { create(:ci_build, :stop_review_app, environment: environment.name, project: environment.project) }
        let(:environment) { create(:environment, state: :available) }

        it 'stops the environment' do
          expect(environment).to be_available

          subject

          expect(environment.reload).to be_stopped
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
