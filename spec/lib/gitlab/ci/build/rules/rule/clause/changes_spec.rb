# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Changes do
  describe '#satisfied_by?' do
    subject { described_class.new(globs).satisfied_by?(pipeline, context) }

    it_behaves_like 'a glob matching rule' do
      let(:pipeline) { build(:ci_pipeline) }
      let(:context) {}

      before do
        allow(pipeline).to receive(:modified_paths).and_return(files.keys)
      end
    end

    context 'when pipeline is nil' do
      let(:pipeline) {}
      let(:context) {}
      let(:globs) { [] }

      it { is_expected.to be_truthy }
    end

    context 'when using variable expansion' do
      let(:pipeline) { build(:ci_pipeline) }
      let(:modified_paths) { ['helm/test.txt'] }
      let(:globs) { ['$HELM_DIR/**/*'] }
      let(:context) { double('context') }

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
        let(:globs) { ['path/with/$in/it/*'] }
        let(:modified_paths) { ['path/with/$in/it/file.txt'] }

        before do
          allow(context).to receive(:variables_hash).and_return({})
        end

        it { is_expected.to be_truthy }
      end
    end
  end
end
