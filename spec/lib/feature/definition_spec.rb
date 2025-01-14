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
      :name            | 'colon:separated'          | /Feature flag 'colon:separated' is invalid/
      :name            | 'space separated'          | /Feature flag 'space separated' is invalid/
      :name            | 'ALL_CAPS'                 | /Feature flag 'ALL_CAPS' is invalid/
      :name            | nil                        | /Feature flag is missing name/
      :path            | nil                        | /Feature flag 'feature_flag' is missing path/
      :type            | nil                        | /Feature flag 'feature_flag' is missing `type`/
      :type            | 'invalid'                  | /Feature flag 'feature_flag' type 'invalid' is invalid/
      :path            | 'development/invalid.yml'  | /Feature flag 'feature_flag' has an invalid path/
      :path            | 'invalid/feature_flag.yml' | /Feature flag 'feature_flag' has an invalid path/
      :default_enabled | nil                        | /Feature flag 'feature_flag' is missing `default_enabled`/
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
    let(:attributes) do
      { name: 'feature_flag',
        type: 'beta',
        default_enabled: true }
    end

    let(:path) { File.join('beta', 'feature_flag.yml') }

    it 'raises exception for invalid type' do
      expected_error_message = "The given `type: :invalid` for `feature_flag` is not equal to the " \
                               ":beta set in its definition file. Ensure to use a valid type " \
                               "in beta/feature_flag.yml or ensure that you use a valid syntax:\n\n" \
                               "Feature.enabled?(:my_feature_flag, project, type: :beta)\n" \
                               "push_frontend_feature_flag(:my_feature_flag, project)\n"
      expect { definition.valid_usage!(type_in_code: :invalid) }
        .to raise_error(Feature::InvalidFeatureFlagError, expected_error_message)
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

    after do
      FileUtils.rm_rf(store1)
      FileUtils.rm_rf(store2)
    end

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

    it "when one flag has an invalid milestone it does raise exception" do
      attributes['milestone'] = 17.1
      write_feature_flag(store1, path, yaml_content)

      expect { subject }
        .to raise_error(/Feature flag 'feature_flag' milestone must be a string/)
    end

    def write_feature_flag(store, path, content)
      path = File.join(store, path)
      dir = File.dirname(path)
      FileUtils.mkdir_p(dir)
      File.write(path, content)
    end
  end

  describe '.for_upcoming_milestone?' do
    using RSpec::Parameterized::TableSyntax

    let(:definition) do
      described_class.new(
        "development/enabled_feature_flag.yml",
        name: :enabled_feature_flag,
        type: 'development',
        milestone: milestone,
        default_enabled: false
      )
    end

    before do
      allow(Gitlab).to receive(:version_info).and_return(Gitlab::VersionInfo.parse(current_milestone))
    end

    subject { definition.for_upcoming_milestone? }

    where(:ctx, :milestone, :current_milestone, :expected) do
      'no milestone'               | nil     | '1.0.0'   | false
      'upcoming milestone - major' | '2.3'   | '1.9.999' | true
      'upcoming milestone - minor' | '2.3'   | '2.2.999' | true
      'current milestone'          | '2.3'   | '2.3.999' | true
      'past milestone - major'     | '1.9'   | '2.3.999' | false
      'past milestone - minor'     | '2.2'   | '2.3.999' | false
    end

    with_them do
      it { is_expected.to be(expected) }
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

        described_class.valid_usage!(:feature_flag, type: :development)
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
            described_class.valid_usage!(:unknown_feature_flag, type: :development)
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
            described_class.valid_usage!(:unknown_feature_flag, type: :development)
          end.not_to raise_error
        end
      end

      context 'for an unknown type' do
        it 'raises exception' do
          expect do
            described_class.valid_usage!(:unknown_feature_flag, type: :unknown_type)
          end.to raise_error(/Unknown feature flag type used: `unknown_type`/)
        end
      end
    end
  end

  describe '.log_states?' do
    using RSpec::Parameterized::TableSyntax

    let(:definition) do
      described_class.new(
        "development/enabled_feature_flag.yml",
        name: :enabled_feature_flag,
        type: 'development',
        milestone: milestone,
        log_state_changes: log_state_change,
        default_enabled: false
      )
    end

    before do
      stub_feature_flag_definition(:enabled_feature_flag,
        milestone: milestone,
        log_state_changes: log_state_change)

      allow(Gitlab).to receive(:version_info).and_return(Gitlab::VersionInfo.new(10, 0, 0))
    end

    subject { described_class.log_states?(key) }

    where(:ctx, :key, :milestone, :log_state_change, :expected) do
      'When flag does not exist'                    | :no_flag              | "0.0"  | true  | false
      'When flag is old, and logging is not forced' | :enabled_feature_flag | "0.0"  | false | false
      'When flag is old, but logging is forced'     | :enabled_feature_flag | "0.0"  | true  | true
      'When flag is current'                        | :enabled_feature_flag | "10.0" | true  | true
      'Flag is upcoming'                            | :enabled_feature_flag | "10.0" | true  | true
    end

    with_them do
      it { is_expected.to be(expected) }
    end
  end

  describe '.default_enabled?' do
    subject { described_class.default_enabled?(key, default_enabled_if_undefined: default_value) }

    context 'when feature flag exist' do
      let(:key) { definition.key }
      let(:default_value) { nil }

      before do
        allow(described_class).to receive(:definitions) do
          { definition.key => definition }
        end
      end

      context 'when default_enabled is true' do
        it 'returns the value from the definition' do
          expect(subject).to eq(true)
        end
      end

      context 'when default_enabled is false' do
        let(:attributes) do
          { name: 'feature_flag',
            type: 'development',
            default_enabled: false }
        end

        it 'returns the value from the definition' do
          expect(subject).to eq(false)
        end
      end
    end

    context 'when feature flag does not exist' do
      let(:key) { :unknown_feature_flag }

      context 'when passing default value' do
        let(:default_value) { false }

        it 'returns default value' do
          expect(subject).to eq(default_value)
        end
      end

      context 'when default value is undefined' do
        let(:default_value) { nil }

        context 'when on dev or test environment' do
          it 'raises an error' do
            expect { subject }.to raise_error(
              Feature::InvalidFeatureFlagError,
              "The feature flag YAML definition for 'unknown_feature_flag' does not exist")
          end
        end

        context 'when on production environment' do
          before do
            allow(Gitlab::ErrorTracking).to receive(:should_raise_for_dev?).and_return(false)
          end

          it 'returns false' do
            expect(subject).to eq(false)
          end
        end
      end
    end
  end
end
