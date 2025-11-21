# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Seeder, feature_category: :shared do
  describe 'scopes' do
    it 'has not_mass_generated scope' do
      Gitlab::Seeder.quiet do
        expect { Namespace.not_mass_generated }.not_to raise_error
        expect { Project.not_mass_generated }.not_to raise_error
        expect { User.not_mass_generated }.not_to raise_error
      end
    end

    it 'includes Seed modules' do
      Gitlab::Seeder.quiet do
        expect(Namespace).to include_module(Gitlab::Seeder::NamespaceSeed)
        expect(Project).to include_module(Gitlab::Seeder::ProjectSeed)
        expect(User).to include_module(Gitlab::Seeder::UserSeed)
      end
    end
  end

  describe '.quiet' do
    let(:database_base_models) do
      {
        main: ActiveRecord::Base,
        ci: Ci::ApplicationRecord,
        sec: SecApplicationRecord
      }
    end

    it 'disables database logging' do
      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return(database_base_models.with_indifferent_access)

      described_class.quiet do
        database_base_models.each do |name, model|
          expect(model.logger).to be_nil if database_exists?(name)
        end
      end

      database_base_models.each do |name, model|
        expect(model.logger).not_to be_nil if database_exists?(name)
      end
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

    it 'does not enable SafeRequestStore in production' do
      allow(Rails.env).to receive(:development?).and_return(false)
      expect(Gitlab::SafeRequestStore).not_to receive(:ensure_request_store)
      described_class.quiet { 1 }
    end

    it 'enables the SafeRequestStore in development' do
      allow(Rails.env).to receive(:development?).and_return(true)
      expect(Gitlab::SafeRequestStore).to receive(:ensure_request_store).and_call_original
      original_value = ENV['GITALY_DISABLE_REQUEST_LIMITS']
      described_class.quiet do
        expect(ENV['GITALY_DISABLE_REQUEST_LIMITS']).to eq('true')
      end
      expect(ENV['GITALY_DISABLE_REQUEST_LIMITS']).to eq(original_value)
    end
  end

  describe '.log_message' do
    it 'prepends timestamp to the logged message' do
      freeze_time do
        message = "some message."
        expect { described_class.log_message(message) }.to output(/#{Time.current}: #{message}/).to_stdout
      end
    end
  end
end
