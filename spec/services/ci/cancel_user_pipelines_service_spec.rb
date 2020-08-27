# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CancelUserPipelinesService do
  describe '#execute' do
    let(:user) { create(:user) }

    subject { described_class.new.execute(user) }

    context 'when user has running CI pipelines' do
      let(:pipeline) { create(:ci_pipeline, :running, user: user) }
      let!(:build) { create(:ci_build, :running, pipeline: pipeline) }

      it 'cancels all running pipelines and related jobs', :sidekiq_might_not_need_inline do
        subject

        expect(pipeline.reload).to be_canceled
        expect(build.reload).to be_canceled
      end
    end

    context 'when an error ocurrs' do
      it 'raises a service level error' do
        service = double(execute: ServiceResponse.error(message: 'Error canceling pipeline'))
        allow(::Ci::CancelUserPipelinesService).to receive(:new).and_return(service)

        result = subject

        expect(result).to be_a(ServiceResponse)
        expect(result).to be_error
      end
    end
  end
end
