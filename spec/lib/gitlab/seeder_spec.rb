# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Seeder do
  describe '.quiet' do
    let(:database_base_models) do
      {
        main: ApplicationRecord,
        ci: Ci::ApplicationRecord
      }
    end

    it 'disables database logging' do
      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return(database_base_models.with_indifferent_access)

      described_class.quiet do
        expect(ApplicationRecord.logger).to be_nil
        expect(Ci::ApplicationRecord.logger).to be_nil
      end

      expect(ApplicationRecord.logger).not_to be_nil
      expect(Ci::ApplicationRecord.logger).not_to be_nil
    end

    it 'disables mail deliveries' do
      expect(ActionMailer::Base.perform_deliveries).to eq(true)

      described_class.quiet do
        expect(ActionMailer::Base.perform_deliveries).to eq(false)
      end

      expect(ActionMailer::Base.perform_deliveries).to eq(true)
    end

    it 'disables new note notifications' do
      note = create(:note_on_issue)

      notification_service = NotificationService.new

      expect(notification_service).to receive(:send_new_note_notifications).twice

      notification_service.new_note(note)

      described_class.quiet do
        expect(notification_service.new_note(note)).to eq(nil)
      end

      notification_service.new_note(note)
    end
  end
end
