# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PipelineNotificationWorker, :mailer, feature_category: :continuous_integration do
  let_it_be(:pipeline) { create(:ci_pipeline) }

  describe '#execute' do
    it 'calls NotificationService#pipeline_finished when the pipeline exists' do
      notification_service_double = double
      expect(notification_service_double).to receive(:pipeline_finished)
        .with(pipeline, ref_status: 'success', recipients: ['test@gitlab.com'])
      expect(NotificationService).to receive(:new).and_return(notification_service_double)

      subject.perform(pipeline.id, 'ref_status' => 'success', 'recipients' => ['test@gitlab.com'])
    end

    it 'does nothing when the pipeline does not exist' do
      expect(NotificationService).not_to receive(:new)

      subject.perform(non_existing_record_id)
    end

    context 'when the user is blocked' do
      before do
        expect_next_found_instance_of(Ci::Pipeline) do |pipeline|
          allow(pipeline).to receive(:user) { build(:user, :blocked) }
        end
      end

      it 'does nothing' do
        expect(NotificationService).not_to receive(:new)

        subject.perform(pipeline.id)
      end
    end

    it_behaves_like 'worker with data consistency',
      described_class,
      data_consistency: :delayed
  end
end
