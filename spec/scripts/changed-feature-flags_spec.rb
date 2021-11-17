# frozen_string_literal: true

require 'fast_spec_helper'

load File.expand_path('../../scripts/changed-feature-flags', __dir__)

RSpec.describe 'scripts/changed-feature-flags' do
  describe GetFeatureFlagsFromFiles do
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

    after do
      FileUtils.remove_entry(ff_dir, true)
    end

    describe '.extracted_flags' do
      shared_examples 'extract feature flags' do
        it 'returns feature flags on their own' do
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
      end

      context 'with definition files in the development directory' do
        let(:ff_dir) { FileUtils.mkdir_p(File.join(Dir.tmpdir, 'feature_flags', 'development')) }

        it_behaves_like 'extract feature flags'
      end

      context 'with definition files in the ops directory' do
        let(:ff_dir) { FileUtils.mkdir_p(File.join(Dir.tmpdir, 'feature_flags', 'ops')) }

        it_behaves_like 'extract feature flags'
      end

      context 'with definition files in the experiment directory' do
        let(:ff_dir) { FileUtils.mkdir_p(File.join(Dir.tmpdir, 'feature_flags', 'experiment')) }

        it 'ignores the files' do
          subject = described_class.new({ files: [feature_flag_definition1.path, feature_flag_definition2.path] })

          expect(subject.extracted_flags).to eq('')
        end
      end
    end
  end
end
