# frozen_string_literal: true

require 'fast_spec_helper'
require 'tmpdir'

load File.expand_path('../../scripts/changed-feature-flags', __dir__)

RSpec.describe 'scripts/changed-feature-flags' do
  describe GetFeatureFlagsFromFiles do
    let!(:feature_flag_definition1) do
      file = File.open(File.join(ff_dir, "#{file_name1}.yml"), 'w+')
      file.write(<<~YAML)
        ---
        name: foo_flag
        default_enabled: true
      YAML
      file.rewind
      file
    end

    let!(:feature_flag_definition2) do
      file = File.open(File.join(ff_dir, "#{file_name2}.yml"), 'w+')
      file.write(<<~YAML)
        ---
        name: bar_flag
        default_enabled: false
      YAML
      file.rewind
      file
    end

    let!(:feature_flag_diff1) do
      FileUtils.mkdir_p(File.join(diffs_dir, ff_sub_dir))
      file = File.open(File.join(diffs_dir, ff_sub_dir, "#{file_name1}.yml.diff"), 'w+')
      file.write(<<~YAML)
        @@ -5,4 +5,4 @@
        name: foo_flag
        -default_enabled: false
        +default_enabled: true
      YAML
      file.rewind
      file
    end

    let!(:feature_flag_diff2) do
      FileUtils.mkdir_p(File.join(diffs_dir, ff_sub_dir))
      file = File.open(File.join(diffs_dir, ff_sub_dir, "#{file_name2}.yml.diff"), 'w+')
      file.write(<<~YAML)
        @@ -0,0 +0,0 @@
        name: bar_flag
        -default_enabled: true
        +default_enabled: false
      YAML
      file.rewind
      file
    end

    let!(:deleted_feature_flag_diff) do
      FileUtils.mkdir_p(File.join(diffs_dir, ff_sub_dir))
      file = File.open(File.join(diffs_dir, ff_sub_dir, "foobar_ff_#{SecureRandom.hex(8)}.yml.deleted.diff"), 'w+')
      file.write(<<~YAML)
        @@ -0,0 +0,0 @@
        -name: foobar_flag
        -default_enabled: true
      YAML
      file.rewind
      file
    end

    before do
      allow(Dir).to receive(:pwd).and_return(Dir.tmpdir)
    end

    after do
      feature_flag_definition1.close
      feature_flag_definition2.close
      feature_flag_diff1.close
      feature_flag_diff2.close
      deleted_feature_flag_diff.close
      FileUtils.rm_r(ff_dir)
      FileUtils.rm_r(diffs_dir)
    end

    describe '.extracted_flags' do
      let(:file_name1) { "foo_ff_#{SecureRandom.hex(8)}" }
      let(:file_name2) { "bar_ff_#{SecureRandom.hex(8)}" }
      let(:ff_dir) { FileUtils.mkdir_p(File.join(Dir.tmpdir, ff_sub_dir)) }
      let(:diffs_dir) { FileUtils.mkdir_p(File.join(Dir.tmpdir, 'diffs')).first }

      shared_examples 'extract feature flags' do
        it 'returns feature flags on their own' do
          subject = described_class.new({ files: diffs_dir })

          expect(subject.extracted_flags.split(',')).to include('foo_flag', 'bar_flag')
        end

        it 'returns feature flags and their state as enabled' do
          subject = described_class.new({ files: diffs_dir, state: 'enabled' })

          expect(subject.extracted_flags.split(',')).to include('foo_flag=enabled', 'bar_flag=enabled')
        end

        it 'returns feature flags and their state as disabled' do
          subject = described_class.new({ files: diffs_dir, state: 'disabled' })

          expect(subject.extracted_flags.split(',')).to include('foo_flag=disabled', 'bar_flag=disabled')
        end

        it 'does not return feature flags when there are mixed deleted and non-deleted definition files' do
          subject = described_class.new({ files: diffs_dir, state: 'deleted' })

          expect(subject.extracted_flags).to eq('')
        end
      end

      context 'with definition files in the development directory' do
        let(:ff_sub_dir) { %w[feature_flags development] }

        it_behaves_like 'extract feature flags'
      end

      context 'with definition files in the ops directory' do
        let(:ff_sub_dir) { %w[feature_flags ops] }

        it_behaves_like 'extract feature flags'
      end

      context 'with definition files in the experiment directory' do
        let(:ff_sub_dir) { %w[feature_flags experiment] }

        it 'ignores the files' do
          subject = described_class.new({ files: diffs_dir })

          expect(subject.extracted_flags).to eq('')
        end
      end

      context 'with only deleted definition files' do
        let(:ff_sub_dir) { %w[feature_flags development] }

        before do
          feature_flag_diff1.close
          feature_flag_diff2.close
          FileUtils.rm_r(feature_flag_diff1)
          FileUtils.rm_r(feature_flag_diff2)
        end

        it 'returns feature flags and their state as deleted' do
          subject = described_class.new({ files: diffs_dir, state: 'deleted' })

          expect(subject.extracted_flags).to eq('foobar_flag=deleted')
        end

        it 'does not return feature flags when the desired state is enabled' do
          subject = described_class.new({ files: diffs_dir, state: 'enabled' })

          expect(subject.extracted_flags).to eq('')
        end

        it 'does not return feature flags when the desired state is disabled' do
          subject = described_class.new({ files: diffs_dir, state: 'disabled' })

          expect(subject.extracted_flags).to eq('')
        end
      end
    end
  end
end
