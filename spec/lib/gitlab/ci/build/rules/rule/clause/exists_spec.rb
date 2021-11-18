# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Exists do
  shared_examples 'an exists rule with a context' do
    subject { described_class.new(globs).satisfied_by?(pipeline, context) }

    it_behaves_like 'a glob matching rule' do
      let(:project) { create(:project, :custom_repo, files: files) }
    end

    context 'after pattern comparision limit is reached' do
      let(:globs) { ['*definitely_not_a_matching_glob*'] }
      let(:project) { create(:project, :repository) }

      before do
        stub_const('Gitlab::Ci::Build::Rules::Rule::Clause::Exists::MAX_PATTERN_COMPARISONS', 2)
        expect(File).to receive(:fnmatch?).twice.and_call_original
      end

      it { is_expected.to be_truthy }
    end
  end

  describe '#satisfied_by?' do
    let(:pipeline) { build(:ci_pipeline, project: project, sha: project.repository.head_commit.sha) }

    context 'when context is Build::Context::Build' do
      it_behaves_like 'an exists rule with a context' do
        let(:context) { Gitlab::Ci::Build::Context::Build.new(pipeline, sha: 'abc1234') }
      end
    end

    context 'when context is Build::Context::Global' do
      it_behaves_like 'an exists rule with a context' do
        let(:context) { Gitlab::Ci::Build::Context::Global.new(pipeline, yaml_variables: {}) }
      end
    end

    context 'when context is Config::External::Context' do
      it_behaves_like 'an exists rule with a context' do
        let(:context) { Gitlab::Ci::Config::External::Context.new(project: project, sha: project.repository.tree.sha) }
      end
    end
  end
end
