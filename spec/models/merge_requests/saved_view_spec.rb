# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::SavedView, feature_category: :code_review_workflow do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:other_user) { create(:user) }

  describe 'table name' do
    it 'does not use the Rails-inferred name, which collides with work item saved views' do
      expect(described_class.table_name).to eq('merge_request_saved_views')
    end
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_length_of(:name).is_at_most(255) }

    it 'requires a user' do
      expect(build(:merge_request_saved_view, user: nil)).to be_invalid
    end
  end

  describe 'name uniqueness' do
    let_it_be(:existing) { create(:merge_request_saved_view, user: user, name: 'My view') }

    it 'rejects a duplicate name for the same user' do
      duplicate = build(:merge_request_saved_view, user: user, name: 'My view')

      expect(duplicate).to be_invalid
      expect(duplicate.errors[:name]).to include('has already been taken')
    end

    it 'allows the same name for a different user' do
      expect(build(:merge_request_saved_view, user: other_user, name: 'My view')).to be_valid
    end

    it 'is case sensitive' do
      expect(build(:merge_request_saved_view, user: user, name: 'my view')).to be_valid
    end

    it 'is enforced at the database level' do
      duplicate = build(:merge_request_saved_view, user: user, name: 'My view')

      expect { duplicate.save!(validate: false) }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end

  describe 'filters json schema validation' do
    subject(:saved_view) { build(:merge_request_saved_view, user: user, filters: filters) }

    context 'with a valid payload' do
      where(:filters) do
        [
          {},
          {
            'state' => 'merged',
            'sort' => 'merged_at_desc',
            'draft' => false,
            'author_username' => 'alice',
            'assignee_usernames' => %w[bob carol],
            'reviewer_username' => 'dave',
            'approved_by' => %w[erin],
            'label_name' => %w[bug backend],
            'milestone_title' => '19.3',
            'source_branches' => %w[feature-a],
            'target_branches' => %w[master],
            'merged_after' => '2026-07-01T00:00:00Z',
            'merged_before' => '2026-07-31T23:59:59Z',
            'not' => {
              'author_username' => 'frank',
              'assignee_usernames' => %w[grace],
              'reviewer_username' => 'heidi',
              'approved_by' => %w[ivan],
              'label_name' => %w[frontend],
              'milestone_title' => '19.2',
              'source_branches' => %w[feature-b],
              'target_branches' => %w[stable]
            }
          }
        ]
      end

      with_them do
        it { is_expected.to be_valid }
      end
    end

    context 'with an invalid payload' do
      where(:filters) do
        [
          nil,
          [],
          { 'unknown_filter' => 'value' },
          { 'not' => { 'unknown_filter' => 'value' } },
          { 'state' => 1 },
          { 'state' => 'reopened' },
          { 'sort' => 'UPDATED_DESC' },
          { 'assignee_usernames' => 'bob' },
          { 'draft' => 'true' },
          { 'author_username' => '' },
          { 'merged_after' => '2026-07-01' },
          { 'label_name' => ['bug', ''] },
          { 'label_name' => ('a'..'z').to_a },
          { 'approved_by' => %w[a b c d e f] },
          { 'not' => { 'label_name' => ('a'..'z').to_a } },
          { 'not' => { 'approved_by' => %w[a b c d e f] } },
          { 'not' => { 'milestone_title' => '' } }
        ]
      end

      with_them do
        it { is_expected.to be_invalid }
      end
    end

    it 'sets a helpful error message' do
      saved_view = build(:merge_request_saved_view, user: user, filters: nil)

      expect(saved_view).to be_invalid
      expect(saved_view.errors[:filters]).to include('must be a valid json schema')
    end

    context 'when the payload is just under the size limit' do
      let(:filters) { { 'source_branches' => Array.new(500) { |n| format('branch-%04d', n) } } }

      it { is_expected.to be_valid }
    end

    context 'when the payload exceeds the size limit' do
      let(:filters) { { 'source_branches' => Array.new(1000) { |n| "branch-#{n}" } } }

      it 'is invalid' do
        expect(saved_view).to be_invalid
        expect(saved_view.errors[:filters]).to include('is too large. Maximum size allowed is 8 KiB')
      end
    end
  end

  describe '.views_limit' do
    it 'returns the CE limit' do
      expect(described_class.views_limit).to eq(5)
    end
  end

  describe 'views limit validation' do
    context 'when the user is one below the limit' do
      let_it_be(:existing_views) { create_list(:merge_request_saved_view, 4, user: user) }

      it 'allows a view to be created up to the limit' do
        expect(build(:merge_request_saved_view, user: user)).to be_valid
      end
    end

    context 'when the user is at the limit' do
      let_it_be_with_reload(:existing_views) { create_list(:merge_request_saved_view, 5, user: user) }

      it 'rejects a new view' do
        saved_view = build(:merge_request_saved_view, user: user)

        expect(saved_view).to be_invalid
        expect(saved_view.errors[:base]).to include('You can create a maximum of 5 saved views.')
      end

      it 'does not affect a different user' do
        expect(build(:merge_request_saved_view, user: other_user)).to be_valid
      end

      it 'allows an existing view to be updated' do
        saved_view = existing_views.first

        expect(saved_view.update(name: 'Renamed view')).to be(true)
      end
    end
  end

  describe '.for_user' do
    let_it_be(:user_view) { create(:merge_request_saved_view, user: user) }
    let_it_be(:another_user_view) { create(:merge_request_saved_view, user: user) }
    let_it_be(:other_user_view) { create(:merge_request_saved_view, user: other_user) }

    it 'returns all the views belonging to the given user and no others' do
      expect(described_class.for_user(user)).to contain_exactly(user_view, another_user_view)
    end
  end
end
