# frozen_string_literal: true

require 'spec_helper'

describe PipelineNotificationWorker, :mailer do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  describe '#execute' do
    it 'calls NotificationService#pipeline_finished when the pipeline exists' do
      notification_service_double = double
      expect(notification_service_double).to receive(:pipeline_finished)
        .with(pipeline, ref_status: 'success', recipients: ['test@gitlab.com'])
      expect(NotificationService).to receive(:new).and_return(notification_service_double)

      subject.perform(pipeline.id, ref_status: 'success', recipients: ['test@gitlab.com'])
    end

    it 'does nothing when the pipeline does not exist' do
      expect(NotificationService).not_to receive(:new)

      subject.perform(Ci::Pipeline.maximum(:id).to_i.succ)
    end
  end
end
