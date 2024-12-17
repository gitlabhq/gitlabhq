# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Rules, feature_category: :pipeline_composition do
  let(:context) { double(variables_hash: {}) }
  let(:rule_hashes) {}
  let(:pipeline) { instance_double(Ci::Pipeline, project: project, project_id: project.id, sha: 'sha') }
  let_it_be(:project) { create(:project, :custom_repo, files: { 'file.txt' => 'file' }) }

  subject(:rules) { described_class.new(rule_hashes) }

  before do
    allow(context).to receive(:project).and_return(project)
    allow(context).to receive(:pipeline).and_return(pipeline)
  end

  describe '#evaluate' do
    subject(:result) { rules.evaluate(context).pass? }

    context 'when there is no rule' do
      it { is_expected.to eq(true) }
    end

    shared_examples 'with when: specified' do
      context 'with when: never' do
        before do
          rule_hashes.first[:when] = 'never'
        end

        it { is_expected.to eq(false) }
      end

      context 'with when: always' do
        before do
          rule_hashes.first[:when] = 'always'
        end

        it { is_expected.to eq(true) }
      end

      context 'with when: <invalid string>' do
        before do
          rule_hashes.first[:when] = 'on_success'
        end

        it 'raises an error' do
          expect { result }.to raise_error(described_class::InvalidIncludeRulesError, /when unknown value: on_success/)
        end
      end

      context 'with when: null' do
        before do
          rule_hashes.first[:when] = nil
        end

        it { is_expected.to eq(true) }
      end
    end

    context 'when there is a rule with if:' do
      let(:rule_hashes) { [{ if: '$MY_VAR == "hello"' }] }

      context 'when the rule matches' do
        let(:context) { double(variables_hash: { 'MY_VAR' => 'hello' }) }

        it { is_expected.to eq(true) }

        it_behaves_like 'with when: specified'
      end

      context 'when the rule does not match' do
        let(:context) { double(variables_hash: { 'MY_VAR' => 'invalid' }) }

        it { is_expected.to eq(false) }
      end
    end

    context 'when there is a rule with exists:' do
      let(:rule_hashes) { [{ exists: 'file.txt' }] }
      let(:pipeline) { instance_double(Ci::Pipeline, project: project, project_id: project.id, sha: 'sha', id: 1) }

      context 'when the file exists' do
        let(:context) { double(top_level_worktree_paths: ['file.txt']) }

        it { is_expected.to eq(true) }

        it_behaves_like 'with when: specified'
      end

      context 'when the file does not exist' do
        let(:context) { double(top_level_worktree_paths: ['README.md']) }

        it { is_expected.to eq(false) }
      end
    end

    context 'when there is a rule with changes:' do
      let(:rule_hashes) { [{ changes: ['file.txt'] }] }

      shared_examples 'when the pipeline has modified paths' do
        let(:modified_paths) { ['file.txt'] }

        before do
          allow(pipeline).to receive(:modified_paths).and_return(modified_paths)
        end

        context 'when the file has changed' do
          it { is_expected.to eq(true) }

          it_behaves_like 'with when: specified'
        end

        context 'when the file has not changed' do
          let(:modified_paths) { ['README.md'] }

          it { is_expected.to eq(false) }
        end
      end

      it_behaves_like 'when the pipeline has modified paths'

      context 'with paths: specified' do
        let(:rule_hashes) { [{ changes: { paths: ['file.txt'] } }] }

        it_behaves_like 'when the pipeline has modified paths'
      end

      context 'with paths: and compare_to: specified' do
        before_all do
          project.repository.add_branch(project.owner, 'branch1', 'master')

          project.repository.update_file(
            project.owner, 'file.txt', 'file updated', message: 'Update file.txt', branch_name: 'branch1'
          )

          project.repository.add_branch(project.owner, 'branch2', 'branch1')
        end

        let_it_be(:pipeline) do
          build(:ci_pipeline, project: project, ref: 'branch2', sha: project.commit('branch2').sha)
        end

        context 'when the file has changed compared to the given ref' do
          let(:rule_hashes) { [{ changes: { paths: ['file.txt'], compare_to: 'master' } }] }

          it { is_expected.to eq(true) }

          it_behaves_like 'with when: specified'
        end

        context 'when the file has not changed compared to the given ref' do
          let(:rule_hashes) { [{ changes: { paths: ['file.txt'], compare_to: 'branch1' } }] }

          it { is_expected.to eq(false) }
        end

        context 'when compare_to: is invalid' do
          let(:rule_hashes) { [{ changes: { paths: ['file.txt'], compare_to: 'invalid' } }] }

          it 'raises an error' do
            expect { result }.to raise_error(described_class::InvalidIncludeRulesError, /compare_to is not a valid ref/)
          end
        end
      end
    end

    context 'when there is a rule with an invalid key' do
      let(:rule_hashes) { [{ invalid: ['$MY_VAR'] }] }

      it 'raises an error' do
        expect { result }.to raise_error(described_class::InvalidIncludeRulesError, /contains unknown keys: invalid/)
      end
    end
  end
end
