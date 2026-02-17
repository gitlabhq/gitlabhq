# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Usage::ProductUsageDataSetting, feature_category: :service_ping do
  using RSpec::Parameterized::TableSyntax

  let(:application_setting) { instance_double(ApplicationSetting) }

  before do
    allow(ApplicationSetting).to receive(:current).and_return(application_setting)
  end

  describe '.enabled?' do
    context 'when environment variable is set' do
      where(:env_value, :db_value, :expected_result) do
        'true'  | true  | true
        'true'  | false | true
        'True'  | false | true
        'TRUE'  | false | true
        't'     | false | true
        'yes'   | false | true
        'y'     | false | true
        '1'     | false | true
        'on'    | false | true
        'false' | true  | false
        'false' | false | false
        'False' | true  | false
        'FALSE' | true  | false
        'f'     | true  | false
        'no'    | true  | false
        'n'     | true  | false
        '0'     | true  | false
        'off'   | true  | false
        ''      | true  | true
        'invalid' | true | true
      end

      with_them do
        it 'uses the environment variable value' do
          stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', env_value)
          allow(application_setting).to receive(:gitlab_product_usage_data_enabled).and_return(db_value)

          expect(described_class.enabled?).to eq(expected_result)
        end
      end
    end

    context 'when environment variable is not set' do
      before do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', nil)
      end

      it 'returns true when database setting is true' do
        allow(application_setting).to receive(:gitlab_product_usage_data_enabled).and_return(true)

        expect(described_class.enabled?).to be(true)
      end

      it 'returns false when database setting is false' do
        allow(application_setting).to receive(:gitlab_product_usage_data_enabled).and_return(false)

        expect(described_class.enabled?).to be(false)
      end

      it 'returns nil when application settings are not available' do
        allow(ApplicationSetting).to receive(:current).and_return(nil)

        expect(described_class.enabled?).to be_nil
      end
    end

    context 'when environment variable takes precedence over database' do
      it 'uses env var true over database false' do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', 'true')
        allow(application_setting).to receive(:gitlab_product_usage_data_enabled).and_return(false)

        expect(described_class.enabled?).to be(true)
      end

      it 'uses env var false over database true' do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', 'false')
        allow(application_setting).to receive(:gitlab_product_usage_data_enabled).and_return(true)

        expect(described_class.enabled?).to be(false)
      end
    end
  end

  describe '.source' do
    context 'when environment variable is set to a valid boolean string' do
      where(:env_value) do
        %w[true false 1 0 yes no on off]
      end

      with_them do
        it 'returns :environment' do
          stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', env_value)

          expect(described_class.source).to eq(:environment)
        end
      end
    end

    context 'when environment variable is not set' do
      before do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', nil)
      end

      it 'returns :database' do
        expect(described_class.source).to eq(:database)
      end
    end

    context 'when environment variable is empty string' do
      before do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', '')
      end

      it 'returns :database' do
        expect(described_class.source).to eq(:database)
      end
    end

    context 'when environment variable is invalid' do
      before do
        stub_env('GITLAB_PRODUCT_USAGE_DATA_ENABLED', 'invalid')
      end

      it 'returns :database' do
        expect(described_class.source).to eq(:database)
      end
    end
  end
end
