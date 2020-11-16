# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Changes do
  describe '#satisfied_by?' do
    it_behaves_like 'a glob matching rule' do
      let(:pipeline) { build(:ci_pipeline) }

      before do
        allow(pipeline).to receive(:modified_paths).and_return(files.keys)
      end

      subject { described_class.new(globs).satisfied_by?(pipeline, nil) }
    end

    context 'when using variable expansion' do
      let(:pipeline) { build(:ci_pipeline) }
      let(:modified_paths) { ['helm/test.txt'] }
      let(:globs) { ['$HELM_DIR/**/*'] }
      let(:context) { double('context') }

      subject { described_class.new(globs).satisfied_by?(pipeline, context) }

      before do
        allow(pipeline).to receive(:modified_paths).and_return(modified_paths)
      end

      context 'when context is nil' do
        let(:context) {}

        it { is_expected.to be_falsey }
      end

      context 'when context has the specified variables' do
        let(:variables) do
          [{ key: "HELM_DIR", value: "helm", public: true }]
        end

        before do
          allow(context).to receive(:variables).and_return(variables)
        end

        it { is_expected.to be_truthy }
      end

      context 'when variable expansion does not match' do
        let(:globs) { ['path/with/$in/it/*'] }
        let(:modified_paths) { ['path/with/$in/it/file.txt'] }

        before do
          allow(context).to receive(:variables).and_return([])
        end

        it { is_expected.to be_truthy }
      end
    end
  end
end
