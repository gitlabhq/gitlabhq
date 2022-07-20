# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Changes do
  describe '#satisfied_by?' do
    subject { described_class.new(globs).satisfied_by?(pipeline, context) }

    context 'a glob matching rule' do
      using RSpec::Parameterized::TableSyntax

      let(:pipeline) { build(:ci_pipeline) }
      let(:context) {}

      before do
        allow(pipeline).to receive(:modified_paths).and_return(files.keys)
      end

      # rubocop:disable Layout/LineLength
      where(:case_name, :globs, :files, :satisfied) do
        'exact top-level match'      |  ['Dockerfile']                         | { 'Dockerfile' => '', 'Gemfile' => '' }            | true
        'exact top-level match'      | { paths: ['Dockerfile'] }               | { 'Dockerfile' => '', 'Gemfile' => '' }            | true
        'exact top-level no match'   | { paths: ['Dockerfile'] }               | { 'Gemfile' => '' }                                | false
        'pattern top-level match'    | { paths: ['Docker*'] }                  | { 'Dockerfile' => '', 'Gemfile' => '' }            | true
        'pattern top-level no match' | ['Docker*']                             | { 'Gemfile' => '' }                                | false
        'pattern top-level no match' | { paths: ['Docker*'] }                  | { 'Gemfile' => '' }                                | false
        'exact nested match'         | { paths: ['project/build.properties'] } | { 'project/build.properties' => '' }               | true
        'exact nested no match'      | { paths: ['project/build.properties'] } | { 'project/README.md' => '' }                      | false
        'pattern nested match'       | { paths: ['src/**/*.go'] }              | { 'src/gitlab.com/goproject/goproject.go' => '' }  | true
        'pattern nested no match'    | { paths: ['src/**/*.go'] }              | { 'src/gitlab.com/goproject/README.md' => '' }     | false
        'ext top-level match'        | { paths: ['*.go'] }                     | { 'main.go' => '', 'cmd/goproject/main.go' => '' } | true
        'ext nested no match'        | { paths: ['*.go'] }                     | { 'cmd/goproject/main.go' => '' }                  | false
        'ext slash no match'         | { paths: ['/*.go'] }                    | { 'main.go' => '', 'cmd/goproject/main.go' => '' } | false
      end
      # rubocop:enable Layout/LineLength

      with_them do
        it { is_expected.to eq(satisfied) }
      end
    end

    context 'when pipeline is nil' do
      let(:pipeline) {}
      let(:context) {}
      let(:globs) { { paths: [] } }

      it { is_expected.to be_truthy }
    end

    context 'when using variable expansion' do
      let(:pipeline) { build(:ci_pipeline) }
      let(:modified_paths) { ['helm/test.txt'] }
      let(:globs) { { paths: ['$HELM_DIR/**/*'] } }
      let(:context) { instance_double(Gitlab::Ci::Build::Context::Base) }

      before do
        allow(pipeline).to receive(:modified_paths).and_return(modified_paths)
      end

      context 'when context is nil' do
        let(:context) {}

        it { is_expected.to be_falsey }
      end

      context 'when modified paths are nil' do
        let(:modified_paths) {}

        it { is_expected.to be_truthy }
      end

      context 'when context has the specified variables' do
        let(:variables_hash) do
          { 'HELM_DIR' => 'helm' }
        end

        before do
          allow(context).to receive(:variables_hash).and_return(variables_hash)
        end

        it { is_expected.to be_truthy }
      end

      context 'when variable expansion does not match' do
        let(:globs) { { paths: ['path/with/$in/it/*'] } }
        let(:modified_paths) { ['path/with/$in/it/file.txt'] }

        before do
          allow(context).to receive(:variables_hash).and_return({})
        end

        it { is_expected.to be_truthy }
      end
    end
  end
end
