# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActiveHookFilter do
  subject(:filter) { described_class.new(hook) }

  describe '#matches?' do
    context 'for push event hooks' do
      let(:hook) do
        create(:project_hook, push_events: true, push_events_branch_filter: branch_filter)
      end

      context 'branch filter is specified' do
        let(:branch_filter) { 'master' }

        it 'returns true if branch matches' do
          expect(filter.matches?(:push_hooks, { ref: 'refs/heads/master' })).to be true
        end

        it 'returns false if branch does not match' do
          expect(filter.matches?(:push_hooks, { ref: 'refs/heads/my_branch' })).to be false
        end

        it 'returns false if ref is nil' do
          expect(filter.matches?(:push_hooks, {})).to be false
        end

        context 'branch filter contains wildcard' do
          let(:branch_filter) { 'features/*' }

          it 'returns true if branch matches' do
            expect(filter.matches?(:push_hooks, { ref: 'refs/heads/features/my-branch' })).to be true
            expect(filter.matches?(:push_hooks, { ref: 'refs/heads/features/my-branch/something' })).to be true
          end

          it 'returns false if branch does not match' do
            expect(filter.matches?(:push_hooks, { ref: 'refs/heads/master' })).to be false
          end
        end
      end

      context 'branch filter is not specified' do
        let(:branch_filter) { nil }

        it 'returns true' do
          expect(filter.matches?(:push_hooks, { ref: 'refs/heads/master' })).to be true
        end
      end

      context 'branch filter is empty string' do
        let(:branch_filter) { '' }

        it 'acts like branch is not specified' do
          expect(filter.matches?(:push_hooks, { ref: 'refs/heads/master' })).to be true
        end
      end
    end

    context 'for non-push-events hooks' do
      let(:hook) do
        create(:project_hook, issues_events: true, push_events: false, push_events_branch_filter: '')
      end

      it 'returns true as branch filters are not yet supported for these' do
        expect(filter.matches?(:issues_events, { ref: 'refs/heads/master' })).to be true
      end
    end
  end
end
