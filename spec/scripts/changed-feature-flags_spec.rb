# frozen_string_literal: true

require 'fast_spec_helper'

load File.expand_path('../../scripts/changed-feature-flags', __dir__)

RSpec.describe 'scripts/changed-feature-flags' do
  describe GetFeatureFlagsFromFiles do
    let(:ff_dir) { FileUtils.mkdir_p(File.join(Dir.tmpdir, 'feature_flags', 'development')) }

    let(:feature_flag_definition1) do
      file = Tempfile.new('foo.yml', ff_dir)
      file.write(<<~YAML)
        ---
        name: foo_flag
        default_enabled: true
      YAML
      file.rewind
      file
    end

    let(:feature_flag_definition2) do
      file = Tempfile.new('bar.yml', ff_dir)
      file.write(<<~YAML)
        ---
        name: bar_flag
        default_enabled: false
      YAML
      file.rewind
      file
    end

    let(:feature_flag_definition_invalid_path) do
      file = Tempfile.new('foobar.yml')
      file.write(<<~YAML)
        ---
        name: not a feature flag
      YAML
      file.rewind
      file
    end

    after do
      FileUtils.remove_entry(ff_dir, true)
    end

    describe '.extracted_flags' do
      it 'returns feature flags' do
        subject = described_class.new({ files: [feature_flag_definition1.path, feature_flag_definition2.path] })

        expect(subject.extracted_flags).to eq('foo_flag,bar_flag')
      end

      it 'returns feature flags and their state as enabled' do
        subject = described_class.new({ files: [feature_flag_definition1.path, feature_flag_definition2.path], state: 'enabled' })

        expect(subject.extracted_flags).to eq('foo_flag=enabled,bar_flag=enabled')
      end

      it 'returns feature flags and their state as disabled' do
        subject = described_class.new({ files: [feature_flag_definition1.path, feature_flag_definition2.path], state: 'disabled' })

        expect(subject.extracted_flags).to eq('foo_flag=disabled,bar_flag=disabled')
      end

      it 'ignores files that are not in the feature_flags/development directory' do
        subject = described_class.new({ files: [feature_flag_definition_invalid_path.path] })

        expect(subject.extracted_flags).to eq('')
      end
    end
  end
end
