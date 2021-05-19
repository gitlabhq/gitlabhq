# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryPipelineWorker do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline_id, user_id) }

    let(:pipeline) { create(:ci_pipeline) }

    context 'when pipeline exists' do
      let(:pipeline_id) { pipeline.id }

      context 'when user exists' do
        let(:user) { create(:user) }
        let(:user_id) { user.id }

        before do
          pipeline.project.add_maintainer(user)
        end

        it 'retries the pipeline' do
          expect(::Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_return(pipeline)
          expect(pipeline).to receive(:retry_failed).with(having_attributes(id: user_id))

          perform
        end
      end

      context 'when user does not exist' do
        let(:user_id) { 1234 }

        it 'does not retry the pipeline' do
          expect(::Ci::Pipeline).to receive(:find_by_id).with(pipeline_id).and_return(pipeline)
          expect(pipeline).not_to receive(:retry_failed).with(having_attributes(id: user_id))

          perform
        end
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { 1234 }
      let(:user_id) { 1234 }

      it 'returns nil' do
        expect(perform).to be_nil
      end
    end
  end
end
