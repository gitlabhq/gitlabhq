require 'spec_helper'

describe Gitlab::CurrentSettings do
  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')
  end

  shared_context 'with settings in cache' do
    before do
      create(:application_setting)
      described_class.current_application_settings # warm the cache
    end
  end

  describe '#current_application_settings', :use_clean_rails_memory_store_caching do
    it 'allows keys to be called directly' do
      db_settings = create(:application_setting,
        home_page_url: 'http://mydomain.com',
        signup_enabled: false)

      expect(described_class.home_page_url).to eq(db_settings.home_page_url)
      expect(described_class.signup_enabled?).to be_falsey
      expect(described_class.signup_enabled).to be_falsey
      expect(described_class.metrics_sample_interval).to be(15)
    end

    context 'when ENV["IN_MEMORY_APPLICATION_SETTINGS"] is true' do
      before do
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
      end

      it 'returns an in-memory ApplicationSetting object' do
        expect(ApplicationSetting).not_to receive(:current)

        expect(described_class.current_application_settings).to be_a(ApplicationSetting)
        expect(described_class.current_application_settings).not_to be_persisted
      end
    end

    context 'with DB unavailable' do
      context 'and settings in cache' do
        include_context 'with settings in cache'

        it 'fetches the settings from cache without issuing any query' do
          expect(ActiveRecord::QueryRecorder.new { described_class.current_application_settings }.count).to eq(0)
        end
      end

      context 'and no settings in cache' do
        before do
          # For some reason, `allow(described_class).to receive(:connect_to_db?).and_return(false)` causes issues
          # during the initialization phase of the test suite, so instead let's mock the internals of it
          allow(ActiveRecord::Base.connection).to receive(:active?).and_return(false)
          expect(ApplicationSetting).not_to receive(:current)
        end

        it 'returns an in-memory ApplicationSetting object' do
          expect(described_class.current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
        end

        it 'does not issue any query' do
          expect(ActiveRecord::QueryRecorder.new { described_class.current_application_settings }.count).to eq(0)
        end
      end
    end

    context 'with DB available' do
      # This method returns the ::ApplicationSetting.defaults hash
      # but with respect of custom attribute accessors of ApplicationSetting model
      def settings_from_defaults
        ar_wrapped_defaults = ::ApplicationSetting.build_from_defaults.attributes
        ar_wrapped_defaults.slice(*::ApplicationSetting.defaults.keys)
      end

      context 'and settings in cache' do
        include_context 'with settings in cache'

        it 'fetches the settings from cache' do
          # For some reason, `allow(described_class).to receive(:connect_to_db?).and_return(true)` causes issues
          # during the initialization phase of the test suite, so instead let's mock the internals of it
          expect(ActiveRecord::Base.connection).not_to receive(:active?)
          expect(ActiveRecord::Base.connection).not_to receive(:cached_table_exists?)
          expect(ActiveRecord::Migrator).not_to receive(:needs_migration?)
          expect(ActiveRecord::QueryRecorder.new { described_class.current_application_settings }.count).to eq(0)
        end
      end

      context 'and no settings in cache' do
        before do
          allow(ActiveRecord::Base.connection).to receive(:active?).and_return(true)
          allow(ActiveRecord::Base.connection).to receive(:cached_table_exists?).with('application_settings').and_return(true)
        end

        it 'creates default ApplicationSettings if none are present' do
          settings = described_class.current_application_settings

          expect(settings).to be_a(ApplicationSetting)
          expect(settings).to be_persisted
          expect(settings).to have_attributes(settings_from_defaults)
        end

        context 'with migrations pending' do
          before do
            expect(ActiveRecord::Migrator).to receive(:needs_migration?).and_return(true)
          end

          it 'returns an in-memory ApplicationSetting object' do
            settings = described_class.current_application_settings

            expect(settings).to be_a(Gitlab::FakeApplicationSettings)
            expect(settings.sign_in_enabled?).to eq(settings.sign_in_enabled)
            expect(settings.sign_up_enabled?).to eq(settings.sign_up_enabled)
          end

          it 'uses the existing database settings and falls back to defaults' do
            db_settings = create(:application_setting,
                                 home_page_url: 'http://mydomain.com',
                                 signup_enabled: false)
            settings = described_class.current_application_settings
            app_defaults = ApplicationSetting.last

            expect(settings).to be_a(Gitlab::FakeApplicationSettings)
            expect(settings.home_page_url).to eq(db_settings.home_page_url)
            expect(settings.signup_enabled?).to be_falsey
            expect(settings.signup_enabled).to be_falsey

            # Check that unspecified values use the defaults
            settings.reject! { |key, _| [:home_page_url, :signup_enabled].include? key }
            settings.each { |key, _| expect(settings[key]).to eq(app_defaults[key]) }
          end
        end

        context 'when ApplicationSettings.current is present' do
          it 'returns the existing application settings' do
            expect(ApplicationSetting).to receive(:current).and_return(:current_settings)

            expect(described_class.current_application_settings).to eq(:current_settings)
          end
        end

        context 'when the application_settings table does not exists' do
          it 'returns an in-memory ApplicationSetting object' do
            expect(ApplicationSetting).to receive(:create_from_defaults).and_raise(ActiveRecord::StatementInvalid)

            expect(described_class.current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
          end
        end

        context 'when the application_settings table is not fully migrated' do
          it 'returns an in-memory ApplicationSetting object' do
            expect(ApplicationSetting).to receive(:create_from_defaults).and_raise(ActiveRecord::UnknownAttributeError)

            expect(described_class.current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
          end
        end
      end
    end
  end
end
