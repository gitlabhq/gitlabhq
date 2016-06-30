require 'spec_helper'

describe Gitlab::CurrentSettings do
  describe '#current_application_settings' do
    it 'attempts to use cached values first' do
      allow_any_instance_of(Gitlab::CurrentSettings).to receive(:connect_to_db?).and_return(true)
      expect(ApplicationSetting).to receive(:current).and_return(::ApplicationSetting.create_from_defaults)
      expect(ApplicationSetting).not_to receive(:last)

      expect(current_application_settings).to be_a(ApplicationSetting)
    end

    it 'does not attempt to connect to DB or Redis' do
      allow_any_instance_of(Gitlab::CurrentSettings).to receive(:connect_to_db?).and_return(false)
      expect(ApplicationSetting).not_to receive(:current)
      expect(ApplicationSetting).not_to receive(:last)

      expect(current_application_settings).to eq fake_application_settings
    end

    it 'falls back to DB if Redis returns an empty value' do
      allow_any_instance_of(Gitlab::CurrentSettings).to receive(:connect_to_db?).and_return(true)
      expect(ApplicationSetting).to receive(:last).and_call_original

      expect(current_application_settings).to be_a(ApplicationSetting)
    end

    it 'falls back to DB if Redis fails' do
      allow_any_instance_of(Gitlab::CurrentSettings).to receive(:connect_to_db?).and_return(true)
      expect(ApplicationSetting).to receive(:current).and_raise(::Redis::BaseError)
      expect(ApplicationSetting).to receive(:last).and_call_original

      expect(current_application_settings).to be_a(ApplicationSetting)
    end
  end
end
