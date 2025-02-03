# frozen_string_literal: true

require 'fast_spec_helper'
require 'gitlab/rspec/all'
require_relative '../../../scripts/cells/application-settings-analysis'

RSpec.describe ApplicationSettingsAnalysis, feature_category: :tooling do
  let(:stdout) { StringIO.new }

  subject(:analyzer) { described_class.new(stdout: stdout) }

  describe described_class::ApplicationSetting do
    let(:attr) { 'default_branch_name' }
    let(:definition_file_path) { File.expand_path("../../../config/application_setting_columns/#{attr}.yml", __dir__) }
    let(:definition_file_exist) { true }
    let(:definition) { { column: 'default_branch_name', db_type: 'fake type', clusterwide: true } }

    subject(:application_setting) do
      described_class.new(column: 'default_branch_name', db_type: 'text', clusterwide: true)
    end

    before do
      allow(File).to receive(:exist?).and_call_original
      allow(File).to receive(:exist?).with(definition_file_path).and_return(definition_file_exist)
      allow(YAML).to receive(:safe_load_file).with(definition_file_path).and_return(definition)
    end

    describe '#initialize' do
      it 'does not override codebase fields' do
        expect(application_setting.column).to eq('default_branch_name')
        expect(application_setting.db_type).to eq('text')
      end

      context 'when definition file does not' do
        let(:definition_file_exist) { false }

        it 'is not a problem' do
          expect { application_setting }.not_to raise_error
        end
      end
    end

    describe '#definition_file_path' do
      it 'returns the definition file path' do
        expect(application_setting.definition_file_path)
          .to eq(File.expand_path("../../../config/application_setting_columns/#{attr}.yml", __dir__))
      end
    end

    describe '#definition_file_exist?' do
      it 'returns true when the definition file exists' do
        expect(File).to receive(:exist?).with(definition_file_path).and_return(definition_file_exist)

        expect(application_setting.definition_file_exist?).to eq(definition_file_exist)
      end
    end
  end

  describe '#attributes' do
    subject(:attributes) { analyzer.attributes }

    describe 'return value' do
      it 'returns an array of described_class::ApplicationSetting' do
        expect(attributes).to all(be_a(described_class::ApplicationSetting))
      end
    end

    describe 'non-encrypted attribute' do
      it 'returns non-encrypted attributes from db/structure.sql' do
        setting = attributes.find { |attr| attr.column == 'default_branch_name' }

        expect(setting).to be_present
      end
    end

    describe 'DB type' do
      it 'stores the column type from db/structure.sql' do
        setting = attributes.find { |attr| attr.column == 'snippet_size_limit' }

        expect(setting.db_type).to eq('bigint')
      end
    end

    describe 'API type' do
      it 'fetches the API type from doc/api/settings.md' do
        setting = attributes.find { |attr| attr.column == 'snippet_size_limit' }

        expect(setting.api_type).to eq('integer')
      end
    end

    describe 'encrypts columns' do
      let(:attribute) { 'default_branch_protection_defaults' } # use this field since it's an actual JSONB field
      let(:ee_attribute) { 'future_subscriptions' } # use this field since it's an actual JSONB field
      let(:fake_application_setting_file) do
        <<~CLASS
        class ApplicationSetting < ApplicationRecord
          encrypts :#{attribute}
        end
        CLASS
      end

      let(:fake_ee_application_setting_file) do
        <<~MODULE
        module EE
          module ApplicationSetting
            extend ActiveSupport::Concern
            extend ::Gitlab::Utils::Override

            prepended do
              encrypts :#{ee_attribute}
            end
          end
        end
        MODULE
      end

      before do
        stub_const(
          "#{described_class}::ApplicationSetting::AS_MODEL",
          fake_application_setting_file + fake_ee_application_setting_file
        )
      end

      it 'returns encrypted attribute columns from the model' do
        setting = attributes.find { |attr| attr.column == attribute }
        ee_setting = attributes.find { |attr| attr.column == ee_attribute }

        expect(setting.attr).to eq(attribute)
        expect(setting.encrypted).to be(true)

        expect(ee_setting.attr).to eq(ee_attribute)
        expect(ee_setting.encrypted).to be(true)
      end
    end

    describe 'attr_encrypted columns' do
      it 'returns encrypted attribute columns from db/structure.sql' do
        setting = attributes.find { |attr| attr.column == 'encrypted_external_auth_client_key' }
        encryption_iv_column = attributes
          .find { |attr| attr.column == 'encrypted_external_auth_client_key_iv' }

        expect(setting.attr).to eq('external_auth_client_key') # `encrypted_` prefix is removed
        expect(setting.encrypted).to be(true)
        expect(encryption_iv_column).to be_nil # `*_iv` column aren't listed as it's an implementation detail
      end
    end

    describe 'TokenAuthenticatable columns' do
      it 'returns encrypted attribute columns from db/structure.sql' do
        setting = attributes.find { |attr| attr.column == 'runners_registration_token_encrypted' }

        expect(setting.attr).to eq('runners_registration_token') # `_encrypted` suffix is removed
        expect(setting.encrypted).to be(true)
      end
    end

    describe 'column `not null`' do
      it 'stores the column `not null` from db/structure.sql' do
        setting = attributes.find { |attr| attr.column == 'snippet_size_limit' }

        expect(setting.not_null).to be(true)
      end
    end

    describe 'column default' do
      it 'stores the column default from db/structure.sql' do
        setting = attributes.find { |attr| attr.column == 'snippet_size_limit' }

        expect(setting.default).to eq('52428800')
      end
    end

    describe 'attributes different than default on GitLab.com' do
      it 'marks settings that have a different value than default set on GitLab.com' do
        setting = attributes.find { |attr| attr.column == 'zoekt_settings' }

        expect(setting.gitlab_com_different_than_default).to be(true)
      end
    end

    describe 'attribute description' do
      it 'fetches attribute description from doc/api/settings.md' do
        setting = attributes.find { |attr| attr.column == 'commit_email_hostname' }

        expect(setting.description).to eq('Custom hostname (for private commit emails).')
      end
    end

    describe 'JiHu-specific columns' do
      it 'fetches JiHu-specific columns from db/structure.sql' do
        setting = attributes.find { |attr| attr.column == 'content_validation_endpoint_url' }

        expect(setting.jihu).to be(true)
      end
    end

    describe 'HTML caching column' do
      it 'does not return _html-suffixed columns from db/structure.sql' do
        setting = attributes.find { |attr| attr.column.end_with?('_html') }

        expect(setting).to be_nil
      end
    end

    describe 'definition file' do
      it 'returns true when an attribute has an existing definition file' do
        setting = attributes.find { |attr| attr.column == 'commit_email_hostname' }

        expect(setting.definition_file_exist?).to be(true)
      end
    end
  end

  describe '#execute' do
    before do
      allow(File).to receive(:write)
      allow(stdout).to receive(:puts)
    end

    it 'works without issues' do
      analyzer.execute
    end

    context 'when API type is not compatible with DB type' do
      let(:documentation_api_settings) do
        [described_class::ApplicationSettingApiDoc.new(attr: 'default_branch_name', api_type: 'integer')]
      end

      before do
        allow(analyzer).to receive(:documentation_api_settings).and_return(documentation_api_settings)
      end

      it 'raises an error' do
        expect { analyzer.execute }.to raise_error("`default_branch_name`: Documented type `integer` " \
          "isn't compatible with actual DB type `text`!")
      end
    end

    context 'when a definition file exists for an attribute that does not exist anymore' do
      let(:fake_attribute_definition_file_path) do
        File.expand_path("../../../config/application_setting_columns/fake_attribute.yml", __dir__)
      end

      before do
        allow(File).to receive(:unlink).and_call_original
      end

      it 'deletes the definition file' do
        # #definition_files is memoized so the stub it directly
        allow(described_class).to receive(:definition_files).and_return([fake_attribute_definition_file_path])
        expect(stdout).to receive(:puts).with(
          "Deleting #{fake_attribute_definition_file_path} since the fake_attribute attribute doesn't exist anymore."
        )
        expect(File).to receive(:unlink).with(fake_attribute_definition_file_path).and_return(1)

        analyzer.execute
      end
    end
  end

  describe '.definition_files' do
    it 'returns all definition files' do
      expect(described_class.definition_files).to eq(
        Dir.glob(File.expand_path("../../../config/application_setting_columns/*.yml", __dir__))
      )
    end
  end
end
