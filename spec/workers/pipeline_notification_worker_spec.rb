require 'spec_helper'

describe PipelineNotificationWorker, :mailer do
  let(:pipeline) { create(:ci_pipeline) }

  describe '#execute' do
    it 'calls NotificationService#pipeline_finished when the pipeline exists' do
      expect(NotificationService).to receive_message_chain(:new, :pipeline_finished)

      subject.perform(pipeline.id)
    end

    it 'does nothing when the pipeline does not exist' do
      expect(NotificationService).not_to receive(:new)

      subject.perform(Ci::Pipeline.maximum(:id).to_i.succ)
    end
  end
end
