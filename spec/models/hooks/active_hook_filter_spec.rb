# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveHookFilter do
  subject(:filter) { described_class.new(hook) }

  describe '#matches?' do
    using RSpec::Parameterized::TableSyntax

    context 'for various types of branch_filter' do
      let(:hook) do
        build(:project_hook, push_events: true, issues_events: true)
      end

      where(:branch_filter_strategy, :branch_filter, :ref, :expected_matches?) do
        'all_branches'  | 'master'        | 'refs/heads/master'                       | true
        'all_branches'  | ''              | 'refs/heads/master'                       | true
        'all_branches'  | nil             | 'refs/heads/master'                       | true
        'all_branches'  | '.*'            | 'refs/heads/master'                       | true
        'wildcard'      | 'master'        | 'refs/heads/master'                       | true
        'wildcard'      | 'master'        | 'refs/heads/my_branch'                    | false
        'wildcard'      | 'features/*'    | 'refs/heads/features/my-branch'           | true
        'wildcard'      | 'features/*'    | 'refs/heads/features/my-branch/something' | true
        'wildcard'      | 'features/*'    | 'refs/heads/master'                       | false
        'wildcard'      | nil             | 'refs/heads/master'                       | true
        'wildcard'      | ''              | 'refs/heads/master'                       | true
        'regex'         | 'master'        | 'refs/heads/master'                       | true
        'regex'         | 'master'        | 'refs/heads/my_branch'                    | false
        'regex'         | 'features/*'    | 'refs/heads/xxxx/features/my-branch'      | true
        'regex'         | 'features/*'    | 'refs/heads/features/'                    | true
        'regex'         | 'features/*'    | 'refs/heads/features'                     | true
        'regex'         | 'features/.*'   | 'refs/heads/features/my-branch'           | true
        'regex'         | 'features/.*'   | 'refs/heads/features/my-branch/something' | true
        'regex'         | 'features/.*'   | 'refs/heads/master'                       | false
        'regex'         | '(feature|dev)' | 'refs/heads/feature'                      | true
        'regex'         | '(feature|dev)' | 'refs/heads/dev'                          | true
        'regex'         | '(feature|dev)' | 'refs/heads/master'                       | false
        'regex'         | nil             | 'refs/heads/master'                       | true
        'regex'         | ''              | 'refs/heads/master'                       | true
      end

      with_them do
        before do
          hook.assign_attributes(
            push_events_branch_filter: branch_filter,
            branch_filter_strategy: branch_filter_strategy
          )
        end

        it { expect(filter.matches?(:push_hooks, { ref: ref })).to be expected_matches? }
        it { expect(filter.matches?(:issues_events, { ref: ref })).to be true }
      end

      context 'when the branch filter is a invalid regex' do
        let(:hook) do
          build(
            :project_hook,
            push_events: true,
            push_events_branch_filter: 'master',
            branch_filter_strategy: 'regex'
          )
        end

        before do
          allow(hook).to receive(:push_events_branch_filter).and_return("invalid-regex[")
        end

        it { expect(filter.matches?(:push_hooks, { ref: 'refs/heads/master' })).to be false }
      end

      context 'when the branch filter is not properly set to nil' do
        let(:hook) do
          build(
            :project_hook,
            push_events: true,
            branch_filter_strategy: 'all_branches'
          )
        end

        before do
          allow(hook).to receive(:push_events_branch_filter).and_return("master")
        end

        it { expect(filter.matches?(:push_hooks, { ref: 'refs/heads/feature1' })).to be true }
      end
    end
  end
end
