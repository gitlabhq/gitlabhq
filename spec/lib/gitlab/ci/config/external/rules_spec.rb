# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Rules, feature_category: :pipeline_composition do
  let(:rule_hashes) {}

  subject(:rules) { described_class.new(rule_hashes) }

  describe '#evaluate' do
    let(:context) { double(variables_hash: {}) }

    subject(:result) { rules.evaluate(context).pass? }

    context 'when there is no rule' do
      it { is_expected.to eq(true) }
    end

    context 'when there is a rule with if' do
      let(:rule_hashes) { [{ if: '$MY_VAR == "hello"' }] }

      context 'when the rule matches' do
        let(:context) { double(variables_hash: { 'MY_VAR' => 'hello' }) }

        it { is_expected.to eq(true) }
      end

      context 'when the rule does not match' do
        let(:context) { double(variables_hash: { 'MY_VAR' => 'invalid' }) }

        it { is_expected.to eq(false) }
      end
    end

    context 'when there is a rule with exists' do
      let(:project) { create(:project, :repository) }
      let(:context) { double(project: project, sha: project.repository.tree.sha, top_level_worktree_paths: ['test.md']) }
      let(:rule_hashes) { [{ exists: 'Dockerfile' }] }

      context 'when the file does not exist' do
        it { is_expected.to eq(false) }
      end

      context 'when the file exists' do
        let(:context) { double(project: project, sha: project.repository.tree.sha, top_level_worktree_paths: ['Dockerfile']) }

        before do
          project.repository.create_file(project.first_owner, 'Dockerfile', "commit", message: 'test', branch_name: "master")
        end

        it { is_expected.to eq(true) }
      end
    end

    context 'when there is a rule with if and when' do
      let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: 'on_success' }] }

      it 'raises an error' do
        expect { result }.to raise_error(described_class::InvalidIncludeRulesError,
                                         'invalid include rule: {:if=>"$MY_VAR == \"hello\"", :when=>"on_success"}')
      end
    end

    context 'when there is a rule with changes' do
      let(:rule_hashes) { [{ changes: ['$MY_VAR'] }] }

      it 'raises an error' do
        expect { result }.to raise_error(described_class::InvalidIncludeRulesError,
                                         'invalid include rule: {:changes=>["$MY_VAR"]}')
      end
    end
  end
end
