require 'spec_helper'

describe Gitlab::CurrentSettings do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe '#current_application_settings' do
    context 'with DB available' do
      before do
        allow_any_instance_of(described_class).to receive(:connect_to_db?).and_return(true)
      end

      it 'attempts to use cached values first' do
        expect(ApplicationSetting).to receive(:current)
        expect(ApplicationSetting).not_to receive(:last)

        expect(current_application_settings).to be_a(ApplicationSetting)
      end

      it 'falls back to DB if Redis returns an empty value' do
        expect(ApplicationSetting).to receive(:last).and_call_original

        expect(current_application_settings).to be_a(ApplicationSetting)
      end

      it 'falls back to DB if Redis fails' do
        expect(ApplicationSetting).to receive(:current).and_raise(::Redis::BaseError)
        expect(ApplicationSetting).to receive(:last).and_call_original

        expect(current_application_settings).to be_a(ApplicationSetting)
      end
    end

    context 'with DB unavailable' do
      before do
        allow_any_instance_of(described_class).to receive(:connect_to_db?).and_return(false)
      end

      it 'returns an in-memory ApplicationSetting object' do
        expect(ApplicationSetting).not_to receive(:current)
        expect(ApplicationSetting).not_to receive(:last)

        expect(current_application_settings).to be_a(OpenStruct)
      end
    end

    context 'when ENV["IN_MEMORY_APPLICATION_SETTINGS"] is true' do
      before do
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
      end

      it 'returns an in-memory ApplicationSetting object' do
        expect(ApplicationSetting).not_to receive(:current)
        expect(ApplicationSetting).not_to receive(:last)

        expect(current_application_settings).to be_a(ApplicationSetting)
        expect(current_application_settings).not_to be_persisted
      end
    end
  end
end
