require 'spec_helper'

describe Gitlab::CurrentSettings do
  include StubENV

  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  describe '#current_application_settings' do
    it 'allows keys to be called directly' do
      db_settings = create(:application_setting,
                           home_page_url: 'http://mydomain.com',
                           signup_enabled: false)

      expect(described_class.home_page_url).to eq(db_settings.home_page_url)
      expect(described_class.signup_enabled?).to be_falsey
      expect(described_class.signup_enabled).to be_falsey
      expect(described_class.metrics_sample_interval).to be(15)
    end

    context 'with DB available' do
      before do
        # For some reason, `allow(described_class).to receive(:connect_to_db?).and_return(true)` causes issues
        # during the initialization phase of the test suite, so instead let's mock the internals of it
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).and_call_original
        allow(ActiveRecord::Base.connection).to receive(:table_exists?).with('application_settings').and_return(true)
      end

      it 'attempts to use cached values first' do
        expect(ApplicationSetting).to receive(:cached)

        expect(described_class.current_application_settings).to be_a(ApplicationSetting)
      end

      it 'falls back to DB if Redis returns an empty value' do
        expect(ApplicationSetting).to receive(:cached).and_return(nil)
        expect(ApplicationSetting).to receive(:last).and_call_original.twice

        expect(described_class.current_application_settings).to be_a(ApplicationSetting)
      end

      it 'falls back to DB if Redis fails' do
        db_settings = ApplicationSetting.create!(ApplicationSetting.defaults)

        expect(ApplicationSetting).to receive(:cached).and_raise(::Redis::BaseError)
        expect(Rails.cache).to receive(:fetch).with(ApplicationSetting::CACHE_KEY).and_raise(Redis::BaseError)

        expect(described_class.current_application_settings).to eq(db_settings)
      end

      it 'creates default ApplicationSettings if none are present' do
        expect(ApplicationSetting).to receive(:cached).and_raise(::Redis::BaseError)
        expect(Rails.cache).to receive(:fetch).with(ApplicationSetting::CACHE_KEY).and_raise(Redis::BaseError)

        settings = described_class.current_application_settings

        expect(settings).to be_a(ApplicationSetting)
        expect(settings).to be_persisted
        expect(settings).to have_attributes(ApplicationSetting.defaults)
      end

      context 'with migrations pending' do
        before do
          expect(ActiveRecord::Migrator).to receive(:needs_migration?).and_return(true)
        end

        it 'returns an in-memory ApplicationSetting object' do
          settings = described_class.current_application_settings

          expect(settings).to be_a(OpenStruct)
          expect(settings.sign_in_enabled?).to eq(settings.sign_in_enabled)
          expect(settings.sign_up_enabled?).to eq(settings.sign_up_enabled)
        end

        it 'uses the existing database settings and falls back to defaults' do
          db_settings = create(:application_setting,
                               home_page_url: 'http://mydomain.com',
                               signup_enabled: false)
          settings = described_class.current_application_settings
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
        # For some reason, `allow(described_class).to receive(:connect_to_db?).and_return(false)` causes issues
        # during the initialization phase of the test suite, so instead let's mock the internals of it
        allow(ActiveRecord::Base.connection).to receive(:active?).and_return(false)
      end

      it 'returns an in-memory ApplicationSetting object' do
        expect(ApplicationSetting).not_to receive(:current)
        expect(ApplicationSetting).not_to receive(:last)

        expect(described_class.current_application_settings).to be_a(OpenStruct)
      end
    end

    context 'when ENV["IN_MEMORY_APPLICATION_SETTINGS"] is true' do
      before do
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
      end

      it 'returns an in-memory ApplicationSetting object' do
        expect(ApplicationSetting).not_to receive(:current)
        expect(ApplicationSetting).not_to receive(:last)

        expect(described_class.current_application_settings).to be_a(ApplicationSetting)
        expect(described_class.current_application_settings).not_to be_persisted
      end
    end
  end
end
