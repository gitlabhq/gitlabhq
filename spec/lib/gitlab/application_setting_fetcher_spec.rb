# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ApplicationSettingFetcher, feature_category: :cell do
  before do
    stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'false')

    described_class.clear_in_memory_application_settings!
  end

  describe '.clear_in_memory_application_settings!' do
    subject(:clear_in_memory_application_settings!) { described_class.clear_in_memory_application_settings! }

    before do
      stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')

      described_class.current_application_settings
    end

    it 'will re-initialize settings' do
      expect(ApplicationSetting).to receive(:build_from_defaults).and_call_original

      clear_in_memory_application_settings!
      described_class.current_application_settings
    end
  end

  describe '.current_application_settings' do
    subject(:current_application_settings) { described_class.current_application_settings }

    context 'when ENV["IN_MEMORY_APPLICATION_SETTINGS"] is true' do
      before do
        stub_env('IN_MEMORY_APPLICATION_SETTINGS', 'true')
      end

      it 'returns an in-memory ApplicationSetting object' do
        expect(ApplicationSetting).not_to receive(:current)
        expect(ApplicationSetting).to receive(:build_from_defaults).and_call_original

        expect(current_application_settings).to be_a(ApplicationSetting)
        expect(current_application_settings).not_to be_persisted
      end
    end

    context 'when ENV["IN_MEMORY_APPLICATION_SETTINGS"] is false' do
      let_it_be(:settings) { create(:application_setting) }

      context 'and settings in cache' do
        before do
          # Warm the cache
          ApplicationSetting.current
        end

        it 'fetches the settings from cache' do
          expect(::ApplicationSetting).to receive(:cached).and_call_original

          expect(ActiveRecord::QueryRecorder.new { current_application_settings }.count).to eq(0)
        end
      end

      context 'and settings are not in cache' do
        before do
          allow(ApplicationSetting).to receive(:cached).and_return(nil)
        end

        context 'and we are running a Rake task' do
          before do
            allow(Gitlab::Runtime).to receive(:rake?).and_return(true)
          end

          context 'and database does not exist' do
            before do
              allow(::ApplicationSetting.database)
                .to receive(:cached_table_exists?).and_raise(ActiveRecord::NoDatabaseError)
            end

            it 'uses Gitlab::FakeApplicationSettings' do
              expect(current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
            end
          end

          context 'and database connection is not active' do
            before do
              allow(::ApplicationSetting.connection).to receive(:active?).and_return(false)
            end

            it 'uses Gitlab::FakeApplicationSettings' do
              expect(current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
            end
          end

          context 'and table does not exist' do
            before do
              allow(::ApplicationSetting.database).to receive(:cached_table_exists?).and_return(false)
            end

            it 'uses Gitlab::FakeApplicationSettings' do
              expect(current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
            end
          end

          context 'and database connection raises some error' do
            before do
              allow(::ApplicationSetting.connection).to receive(:active?).and_raise(StandardError)
            end

            it 'uses Gitlab::FakeApplicationSettings' do
              expect(current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
            end
          end

          context 'and there are pending database migrations' do
            before do
              allow_next_instance_of(ActiveRecord::MigrationContext) do |migration_context|
                allow(migration_context).to receive(:needs_migration?).and_return(true)
              end
            end

            it 'uses Gitlab::FakeApplicationSettings' do
              expect(current_application_settings).to be_a(Gitlab::FakeApplicationSettings)
            end

            context 'when a new setting is used but the migration did not run yet' do
              let(:default_attributes) { { new_column: 'some_value' } }

              before do
                allow(ApplicationSetting).to receive(:defaults).and_return(default_attributes)
              end

              it 'uses the default value if present' do
                expect(current_application_settings.new_column).to eq(
                  default_attributes[:new_column]
                )
              end
            end
          end
        end

        context 'and settings are in database' do
          it 'returns settings from database' do
            expect(current_application_settings).to eq(settings)
          end
        end

        context 'and settings are not in the database' do
          before do
            allow(ApplicationSetting).to receive(:current).and_return(nil)
          end

          it 'returns default settings' do
            expect(ApplicationSetting).to receive(:create_from_defaults).and_call_original

            expect(current_application_settings).to eq(settings)
          end
        end

        context 'when we hit a recursive loop' do
          before do
            allow(ApplicationSetting).to receive(:current).and_raise(ApplicationSetting::Recursion)
          end

          it 'recovers and returns in-memory settings' do
            settings = described_class.current_application_settings

            expect(settings).to be_a(ApplicationSetting)
            expect(settings).not_to be_persisted
          end
        end
      end
    end
  end

  describe '.expire_current_application_settings' do
    subject(:expire) { described_class.expire_current_application_settings }

    it 'expires ApplicationSetting' do
      expect(ApplicationSetting).to receive(:expire)

      expire
    end
  end

  describe '.current_application_settings?' do
    subject(:settings?) { described_class.current_application_settings? }

    context 'when settings exist' do
      let_it_be(:settings) { create(:application_setting) }

      it { is_expected.to be(true) }
    end

    context 'when settings do not exist' do
      it { is_expected.to be(false) }
    end
  end
end
