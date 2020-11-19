# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Feature::Definition do
  let(:attributes) do
    { name: 'feature_flag',
      type: 'development',
      default_enabled: true }
  end

  let(:path) { File.join('development', 'feature_flag.yml') }
  let(:definition) { described_class.new(path, attributes) }
  let(:yaml_content) { attributes.deep_stringify_keys.to_yaml }

  describe '#key' do
    subject { definition.key }

    it 'returns a symbol from name' do
      is_expected.to eq(:feature_flag)
    end
  end

  describe '#validate!' do
    using RSpec::Parameterized::TableSyntax

    where(:param, :value, :result) do
      :name            | nil                        | /Feature flag is missing name/
      :path            | nil                        | /Feature flag 'feature_flag' is missing path/
      :type            | nil                        | /Feature flag 'feature_flag' is missing type/
      :type            | 'invalid'                  | /Feature flag 'feature_flag' type 'invalid' is invalid/
      :path            | 'development/invalid.yml'  | /Feature flag 'feature_flag' has an invalid path/
      :path            | 'invalid/feature_flag.yml' | /Feature flag 'feature_flag' has an invalid type/
      :default_enabled | nil                        | /Feature flag 'feature_flag' is missing default_enabled/
    end

    with_them do
      let(:params) { attributes.merge(path: path) }

      before do
        params[param] = value
      end

      it do
        expect do
          described_class.new(
            params[:path], params.except(:path)
          ).validate!
        end.to raise_error(result)
      end
    end
  end

  describe '#valid_usage!' do
    context 'validates type' do
      it 'raises exception for invalid type' do
        expect { definition.valid_usage!(type_in_code: :invalid, default_enabled_in_code: false) }
          .to raise_error(/The `type:` of `feature_flag` is not equal to config/)
      end
    end

    context 'validates default enabled' do
      it 'raises exception for different value' do
        expect { definition.valid_usage!(type_in_code: :development, default_enabled_in_code: false) }
          .to raise_error(/The `default_enabled:` of `feature_flag` is not equal to config/)
      end
    end
  end

  describe '.paths' do
    it 'returns at least one path' do
      expect(described_class.paths).not_to be_empty
    end
  end

  describe '.load_from_file' do
    it 'properly loads a definition from file' do
      expect_file_read(path, content: yaml_content)

      expect(described_class.send(:load_from_file, path).attributes)
        .to eq(definition.attributes)
    end

    context 'for missing file' do
      let(:path) { 'missing/feature-flag/file.yml' }

      it 'raises exception' do
        expect do
          described_class.send(:load_from_file, path)
        end.to raise_error(/Invalid definition for/)
      end
    end

    context 'for invalid definition' do
      it 'raises exception' do
        expect_file_read(path, content: '{}')

        expect do
          described_class.send(:load_from_file, path)
        end.to raise_error(/Feature flag is missing name/)
      end
    end
  end

  describe '.load_all!' do
    let(:store1) { Dir.mktmpdir('path1') }
    let(:store2) { Dir.mktmpdir('path2') }
    let(:definitions) { {} }

    before do
      allow(described_class).to receive(:paths).and_return(
        [
          File.join(store1, '**', '*.yml'),
          File.join(store2, '**', '*.yml')
        ]
      )
    end

    subject { described_class.send(:load_all!) }

    it "when there's no feature flags a list of definitions is empty" do
      is_expected.to be_empty
    end

    it "when there's a single feature flag it properly loads them" do
      write_feature_flag(store1, path, yaml_content)

      is_expected.to be_one
    end

    it "when the same feature flag is stored multiple times raises exception" do
      write_feature_flag(store1, path, yaml_content)
      write_feature_flag(store2, path, yaml_content)

      expect { subject }
        .to raise_error(/Feature flag 'feature_flag' is already defined/)
    end

    it "when one of the YAMLs is invalid it does raise exception" do
      write_feature_flag(store1, path, '{}')

      expect { subject }
        .to raise_error(/Feature flag is missing name/)
    end

    after do
      FileUtils.rm_rf(store1)
      FileUtils.rm_rf(store2)
    end

    def write_feature_flag(store, path, content)
      path = File.join(store, path)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      File.write(path, content)
    end
  end

  describe '.valid_usage!' do
    before do
      allow(described_class).to receive(:definitions) do
        { definition.key => definition }
      end
    end

    context 'when a known feature flag is used' do
      it 'validates it usage' do
        expect(definition).to receive(:valid_usage!)

        described_class.valid_usage!(:feature_flag, type: :development, default_enabled: false)
      end
    end

    context 'when an unknown feature flag is used' do
      context 'for a type that is required to have all feature flags registered' do
        before do
          stub_const('Feature::Shared::TYPES', {
            development: { optional: false }
          })
        end

        it 'raises exception' do
          expect do
            described_class.valid_usage!(:unknown_feature_flag, type: :development, default_enabled: false)
          end.to raise_error(/Missing feature definition for `unknown_feature_flag`/)
        end
      end

      context 'for a type that is optional' do
        before do
          stub_const('Feature::Shared::TYPES', {
            development: { optional: true }
          })
        end

        it 'does not raise exception' do
          expect do
            described_class.valid_usage!(:unknown_feature_flag, type: :development, default_enabled: false)
          end.not_to raise_error
        end
      end

      context 'for an unknown type' do
        it 'raises exception' do
          expect do
            described_class.valid_usage!(:unknown_feature_flag, type: :unknown_type, default_enabled: false)
          end.to raise_error(/Unknown feature flag type used: `unknown_type`/)
        end
      end
    end
  end
end
