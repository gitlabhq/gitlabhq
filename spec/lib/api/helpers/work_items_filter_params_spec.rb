# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe API::Helpers::WorkItemsFilterParams, feature_category: :team_planning do
  subject(:transform) { described_class.new(params).transform }

  describe '#transform' do
    context 'with empty params' do
      let(:params) { {} }

      it 'returns empty hash' do
        expect(transform).to eq({})
      end
    end

    context 'with direct mapping params' do
      let(:params) do
        {
          ids: [1, 2, 3],
          state: 'opened',
          author_username: 'john',
          confidential: true,
          my_reaction_emoji: 'thumbsup',
          created_before: '2024-01-01',
          created_after: '2023-01-01',
          updated_before: '2024-01-01',
          updated_after: '2023-01-01',
          closed_before: '2024-01-01',
          closed_after: '2023-01-01',
          due_before: '2024-01-01',
          due_after: '2023-01-01',
          subscribed: :explicitly_subscribed,
          crm_contact_id: '123',
          crm_organization_id: '456',
          include_descendant_work_items: true,
          include_ancestors: true,
          include_descendants: true
        }
      end

      it 'passes through all direct params, and filters' do
        expect(transform).to eq(params)
      end
    end

    context 'with include_archived param' do
      let(:params) { { include_archived: true } }

      it 'transforms include_archived to non_archived with inverted value' do
        expect(transform).to eq(non_archived: false)
      end
    end

    context 'with include_archived set to false' do
      let(:params) { { include_archived: false } }

      it 'transforms include_archived to non_archived with inverted value' do
        expect(transform).to eq(non_archived: true)
      end
    end

    context 'with renamed params' do
      let(:params) do
        {
          assignee_usernames: %w[user1 user2],
          assignee_wildcard_id: 'None',
          types: %w[issue task],
          parent_ids: [1, 2, 3],
          parent_wildcard_id: 'None',
          release_tag_wildcard_id: 'None',
          milestone_wildcard_id: 'None'
        }
      end

      it 'renames or keeps params as expected' do
        expected = {
          assignee_username: %w[user1 user2],
          assignee_id: 'None',
          issue_types: %w[issue task],
          work_item_parent_ids: [1, 2, 3],
          parent_wildcard_id: 'None',
          release_tag: 'None',
          milestone_wildcard_id: 'None'
        }

        expect(transform).to eq(expected)
      end
    end

    context 'with negated params' do
      let(:params) do
        {
          not: {
            assignee_usernames: ['user1'],
            author_username: ['user2'],
            label_name: ['bug'],
            milestone_title: ['v1.0'],
            milestone_wildcard_id: 'Started',
            my_reaction_emoji: 'thumbsup',
            parent_ids: [1, 2],
            release_tag: ['tag1'],
            types: ['issue']
          }
        }
      end

      it 'transforms negated params correctly' do
        expect(transform[:not]).to eq(
          assignee_username: ['user1'],
          author_username: ['user2'],
          label_name: ['bug'],
          milestone_title: ['v1.0'],
          milestone_wildcard_id: 'Started',
          my_reaction_emoji: 'thumbsup',
          work_item_parent_ids: [1, 2],
          release_tag: ['tag1'],
          issue_types: ['issue']
        )
      end
    end

    context 'with union (OR) params' do
      let(:params) do
        {
          or: {
            assignee_usernames: %w[user1 user2],
            author_usernames: %w[user3 user4],
            label_names: %w[bug feature]
          }
        }
      end

      it 'transforms union params correctly' do
        expect(transform[:or]).to eq(
          assignee_username: %w[user1 user2],
          author_username: %w[user3 user4],
          label_name: %w[bug feature]
        )
      end
    end

    context 'with search in param' do
      context 'when in is present with search' do
        let(:params) { { search: 'foo', in: %w[title description] } }

        it 'joins in to a comma-separated string' do
          expect(transform[:in]).to eq('title,description')
        end
      end

      context 'when in is absent' do
        let(:params) { { search: 'foo' } }

        it 'does not add an in key' do
          expect(transform).not_to have_key(:in)
        end
      end
    end

    context 'with timeframe param' do
      context 'when timeframe has start and end' do
        let(:start_date) { Date.new(2024, 1, 1) }
        let(:end_date) { Date.new(2024, 3, 31) }
        let(:params) { { timeframe: { start: start_date, end: end_date } } }

        it 'expands timeframe into start_date and end_date' do
          expect(transform[:start_date]).to eq(start_date)
          expect(transform[:end_date]).to eq(end_date)
        end

        it 'removes the timeframe key' do
          expect(transform).not_to have_key(:timeframe)
        end
      end

      context 'when timeframe is absent' do
        let(:params) { { state: 'opened' } }

        it 'does not add start_date or end_date' do
          expect(transform).not_to have_key(:start_date)
          expect(transform).not_to have_key(:end_date)
        end
      end
    end

    context 'with combined params' do
      let(:params) do
        {
          state: 'opened',
          assignee_usernames: ['user1'],
          label_name: ['bug'],
          not: {
            author_username: ['user2']
          },
          or: {
            label_names: %w[feature enhancement]
          }
        }
      end

      it 'transforms all param types correctly' do
        expect(transform).to eq(
          state: 'opened',
          assignee_username: ['user1'],
          label_name: ['bug'],
          not: { author_username: ['user2'] },
          or: { label_name: %w[feature enhancement] }
        )
      end
    end
  end
end
