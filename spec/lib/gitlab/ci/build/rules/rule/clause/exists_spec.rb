# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Build::Rules::Rule::Clause::Exists do
  describe '#satisfied_by?' do
    subject(:satisfied_by?) { described_class.new(globs).satisfied_by?(nil, context) }

    shared_examples 'a rules:exists with a context' do
      it_behaves_like 'a glob matching rule' do
        let(:project) { create(:project, :custom_repo, files: files) }
      end

      context 'when the rules:exists has a variable' do
        let_it_be(:project) { create(:project, :custom_repo, files: { 'helm/helm_file.txt' => '' }) }

        let(:globs) { ['$HELM_DIR/**/*'] }

        let(:variables_hash) do
          { 'HELM_DIR' => 'helm' }
        end

        before do
          allow(context).to receive(:variables_hash).and_return(variables_hash)
        end

        context 'when the context has the specified variables' do
          it { is_expected.to be_truthy }
        end

        context 'when variable expansion does not match' do
          let(:variables_hash) { {} }

          it { is_expected.to be_falsey }
        end
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

    context 'when the rules are being evaluated at job level' do
      it_behaves_like 'a rules:exists with a context' do
        let(:pipeline) { build(:ci_pipeline, project: project, sha: project.repository.commit.sha) }
        let(:context) { Gitlab::Ci::Build::Context::Build.new(pipeline, sha: project.repository.commit.sha) }
      end
    end

    context 'when the rules are being evaluated for an entire pipeline' do
      it_behaves_like 'a rules:exists with a context' do
        let(:pipeline) { build(:ci_pipeline, project: project, sha: project.repository.commit.sha) }
        let(:context) { Gitlab::Ci::Build::Context::Global.new(pipeline, yaml_variables: {}) }
      end
    end

    context 'when rules are being evaluated with `include`' do
      let(:context) { Gitlab::Ci::Config::External::Context.new(project: project, sha: sha) }

      it_behaves_like 'a rules:exists with a context' do
        let(:sha) { project.repository.commit.sha }
      end

      context 'when context has no project' do
        let(:globs) { ['Dockerfile'] }
        let(:project) {}
        let(:sha) { 'abc1234' }

        it { is_expected.to eq(false) }
      end
    end
  end
end
