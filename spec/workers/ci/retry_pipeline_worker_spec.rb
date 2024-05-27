# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RetryPipelineWorker, feature_category: :continuous_integration do
  describe '#perform' do
    subject(:perform) { described_class.new.perform(pipeline_id, user_id) }

    let_it_be(:pipeline) { create(:ci_pipeline) }
    let_it_be(:user) { create(:user) }

    before_all do
      pipeline.project.add_maintainer(user)
    end

    context 'when pipeline exists' do
      let(:pipeline_id) { pipeline.id }

      context 'when user exists' do
        let(:user_id) { user.id }

        it 'retries the pipeline' do
          expect(::Ci::Pipeline).to receive(:find_by_id).with(pipeline.id).and_return(pipeline)
          expect(pipeline).to receive(:retry_failed).with(having_attributes(id: user_id))

          perform
        end
      end

      context 'when user does not exist' do
        let(:user_id) { non_existing_record_id }

        it 'does not retry the pipeline' do
          expect(::Ci::Pipeline).to receive(:find_by_id).with(pipeline_id).and_return(pipeline)
          expect(pipeline).not_to receive(:retry_failed).with(having_attributes(id: user_id))

          perform
        end
      end
    end

    context 'when pipeline does not exist' do
      let(:pipeline_id) { non_existing_record_id }
      let(:user_id) { user.id }

      it 'returns nil' do
        expect(perform).to be_nil
      end
    end
  end
end
