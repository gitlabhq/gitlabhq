# frozen_string_literal: true

require 'spec_helper'

describe EmailsOnPushService do
  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:recipients) }
    end

    context 'when service is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:recipients) }
    end
  end

  context 'project emails' do
    let(:push_data) { { object_kind: 'push' } }
    let(:project)   { create(:project, :repository) }
    let(:service)   { create(:emails_on_push_service, project: project) }

    it 'does not send emails when disabled' do
      expect(project).to receive(:emails_disabled?).and_return(true)
      expect(EmailsOnPushWorker).not_to receive(:perform_async)

      service.execute(push_data)
    end

    it 'does send emails when enabled' do
      expect(project).to receive(:emails_disabled?).and_return(false)
      expect(EmailsOnPushWorker).to receive(:perform_async)

      service.execute(push_data)
    end
  end
end
