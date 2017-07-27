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

      # This method returns the ::ApplicationSetting.defaults hash
      # but with respect of custom attribute accessors of ApplicationSetting model
      def settings_from_defaults
        defaults = ::ApplicationSetting.defaults
        ar_wrapped_defaults = ::ApplicationSetting.new(defaults).attributes
        ar_wrapped_defaults.slice(*defaults.keys)
      end

      it 'attempts to use cached values first' do
        expect(ApplicationSetting).to receive(:cached)

        expect(current_application_settings).to be_a(ApplicationSetting)
      end

      it 'falls back to DB if Caching returns an empty value' do
        expect(ApplicationSetting).to receive(:cached).and_return(nil)
        expect(ApplicationSetting).to receive(:last).and_call_original

        expect(current_application_settings).to be_a(ApplicationSetting)
      end

      it 'falls back to DB if Caching fails' do
        db_settings = ApplicationSetting.create!(ApplicationSetting.defaults)

        expect(ApplicationSetting).to receive(:cached).and_raise(::Redis::BaseError)
        expect(Rails.cache).to receive(:fetch).with(ApplicationSetting::CACHE_KEY).and_raise(Redis::BaseError)

        expect(current_application_settings).to eq(db_settings)
      end

      it 'creates default ApplicationSettings if none are present' do
        expect(ApplicationSetting).to receive(:cached).and_raise(::Redis::BaseError)
        expect(Rails.cache).to receive(:fetch).with(ApplicationSetting::CACHE_KEY).and_raise(Redis::BaseError)

        settings = current_application_settings

        expect(settings).to be_a(ApplicationSetting)
        expect(settings).to be_persisted
        expect(settings).to have_attributes(settings_from_defaults)
      end

      context 'with migrations pending' do
        before do
          expect(ActiveRecord::Migrator).to receive(:needs_migration?).and_return(true)
        end

        it 'returns an in-memory ApplicationSetting object' do
          settings = current_application_settings

          expect(settings).to be_a(OpenStruct)
          expect(settings.sign_in_enabled?).to eq(settings.sign_in_enabled)
          expect(settings.sign_up_enabled?).to eq(settings.sign_up_enabled)
        end

        it 'uses the existing database settings and falls back to defaults' do
          db_settings = create(:application_setting,
                               home_page_url: 'http://mydomain.com',
                               signup_enabled: false)
          settings = current_application_settings
          app_defaults = ApplicationSetting.last

          expect(settings).to be_a(OpenStruct)
          expect(settings.home_page_url).to eq(db_settings.home_page_url)
          expect(settings.signup_enabled?).to be_falsey
          expect(settings.signup_enabled).to be_falsey

          # Check that unspecified values use the defaults
          settings.reject! { |key, _| [:home_page_url, :signup_enabled].include? key }
          settings.each { |key, _| expect(settings[key]).to eq(app_defaults[key]) }
        end
      end
    end

    context 'with DB unavailable' do
      before do
        allow_any_instance_of(described_class).to receive(:connect_to_db?).and_return(false)
        allow_any_instance_of(described_class).to receive(:retrieve_settings_from_database_cache?).and_return(nil)
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
