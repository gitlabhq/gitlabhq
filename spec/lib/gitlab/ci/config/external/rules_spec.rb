# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::External::Rules, feature_category: :pipeline_composition do
  let(:context) { double(variables_hash: {}) }
  let(:rule_hashes) { [{ if: '$MY_VAR == "hello"' }] }

  subject(:rules) { described_class.new(rule_hashes) }

  describe '#evaluate' do
    subject(:result) { rules.evaluate(context).pass? }

    context 'when there is no rule' do
      let(:rule_hashes) {}

      it { is_expected.to eq(true) }
    end

    shared_examples 'when there is a rule with if' do |rule_matched_result = true, rule_not_matched_result = false|
      context 'when the rule matches' do
        let(:context) { double(variables_hash: { 'MY_VAR' => 'hello' }) }

        it { is_expected.to eq(rule_matched_result) }
      end

      context 'when the rule does not match' do
        let(:context) { double(variables_hash: { 'MY_VAR' => 'invalid' }) }

        it { is_expected.to eq(rule_not_matched_result) }
      end
    end

    shared_examples 'when there is a rule with exists' do |file_exists_result = true, file_not_exists_result = false|
      let(:project) { create(:project, :repository) }

      context 'when the file exists' do
        let(:context) { double(project: project, sha: project.repository.tree.sha, top_level_worktree_paths: ['Dockerfile']) }

        before do
          project.repository.create_file(project.first_owner, 'Dockerfile', "commit", message: 'test', branch_name: "master")
        end

        it { is_expected.to eq(file_exists_result) }
      end

      context 'when the file does not exist' do
        let(:context) { double(project: project, sha: project.repository.tree.sha, top_level_worktree_paths: ['test.md']) }

        it { is_expected.to eq(file_not_exists_result) }
      end
    end

    it_behaves_like 'when there is a rule with if'

    context 'when there is a rule with exists' do
      let(:rule_hashes) { [{ exists: 'Dockerfile' }] }

      it_behaves_like 'when there is a rule with exists'
    end

    context 'when there is a rule with if and when' do
      context 'with when: never' do
        let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: 'never' }] }

        it_behaves_like 'when there is a rule with if', false, false
      end

      context 'with when: always' do
        let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: 'always' }] }

        it_behaves_like 'when there is a rule with if'
      end

      context 'with when: <invalid string>' do
        let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: 'on_success' }] }

        it 'raises an error' do
          expect { result }.to raise_error(described_class::InvalidIncludeRulesError, /when unknown value: on_success/)
        end
      end

      context 'with when: null' do
        let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: nil }] }

        it_behaves_like 'when there is a rule with if'
      end
    end

    context 'when there is a rule with exists and when' do
      context 'with when: never' do
        let(:rule_hashes) { [{ exists: 'Dockerfile', when: 'never' }] }

        it_behaves_like 'when there is a rule with exists', false, false
      end

      context 'with when: always' do
        let(:rule_hashes) { [{ exists: 'Dockerfile', when: 'always' }] }

        it_behaves_like 'when there is a rule with exists'
      end

      context 'with when: <invalid string>' do
        let(:rule_hashes) { [{ exists: 'Dockerfile', when: 'on_success' }] }

        it 'raises an error' do
          expect { result }.to raise_error(described_class::InvalidIncludeRulesError, /when unknown value: on_success/)
        end
      end

      context 'with when: null' do
        let(:rule_hashes) { [{ exists: 'Dockerfile', when: nil }] }

        it_behaves_like 'when there is a rule with exists'
      end
    end

    context 'when there is a rule with changes' do
      let(:rule_hashes) { [{ changes: ['$MY_VAR'] }] }

      it 'raises an error' do
        expect { result }.to raise_error(described_class::InvalidIncludeRulesError, /contains unknown keys: changes/)
      end
    end

    context 'when FF `ci_refactor_external_rules` is disabled' do
      before do
        stub_feature_flags(ci_refactor_external_rules: false)
      end

      context 'when there is no rule' do
        let(:rule_hashes) {}

        it { is_expected.to eq(true) }
      end

      it_behaves_like 'when there is a rule with if'

      context 'when there is a rule with exists' do
        let(:rule_hashes) { [{ exists: 'Dockerfile' }] }

        it_behaves_like 'when there is a rule with exists'
      end

      context 'when there is a rule with if and when' do
        context 'with when: never' do
          let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: 'never' }] }

          it_behaves_like 'when there is a rule with if', false, false
        end

        context 'with when: always' do
          let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: 'always' }] }

          it_behaves_like 'when there is a rule with if'
        end

        context 'with when: <invalid string>' do
          let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: 'on_success' }] }

          it 'raises an error' do
            expect { result }.to raise_error(described_class::InvalidIncludeRulesError,
                                             'invalid include rule: {:if=>"$MY_VAR == \"hello\"", :when=>"on_success"}')
          end
        end

        context 'with when: null' do
          let(:rule_hashes) { [{ if: '$MY_VAR == "hello"', when: nil }] }

          it_behaves_like 'when there is a rule with if'
        end
      end

      context 'when there is a rule with exists and when' do
        context 'with when: never' do
          let(:rule_hashes) { [{ exists: 'Dockerfile', when: 'never' }] }

          it_behaves_like 'when there is a rule with exists', false, false
        end

        context 'with when: always' do
          let(:rule_hashes) { [{ exists: 'Dockerfile', when: 'always' }] }

          it_behaves_like 'when there is a rule with exists'
        end

        context 'with when: <invalid string>' do
          let(:rule_hashes) { [{ exists: 'Dockerfile', when: 'on_success' }] }

          it 'raises an error' do
            expect { result }.to raise_error(described_class::InvalidIncludeRulesError,
                                             'invalid include rule: {:exists=>"Dockerfile", :when=>"on_success"}')
          end
        end

        context 'with when: null' do
          let(:rule_hashes) { [{ exists: 'Dockerfile', when: nil }] }

          it_behaves_like 'when there is a rule with exists'
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
end
