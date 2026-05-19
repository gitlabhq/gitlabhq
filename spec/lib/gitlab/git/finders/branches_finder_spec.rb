# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Git::Finders::BranchesFinder, feature_category: :source_code_management do
  let_it_be(:project) { create(:project, :repository) }

  let(:repository) { project.repository.raw_repository }
  let(:finder) { described_class.new(repository, params, include_commits: include_commits) }
  let(:params) { {} }
  let(:include_commits) { false }

  describe '#execute' do
    subject(:branches) { finder.execute }

    it 'returns Branch objects without commits by default' do
      branches.first(3).each do |branch|
        expect(branch).to be_a(Gitlab::Git::Branch)
        expect(branch.dereferenced_target).to be_nil
      end
    end

    context 'with include_commits: true' do
      let(:include_commits) { true }

      it 'returns Branch objects with hydrated commits' do
        branches.first(3).each do |branch|
          expect(branch).to be_a(Gitlab::Git::Branch)
          expect(branch.dereferenced_target).to be_present
          expect(branch.dereferenced_target).to respond_to(:sha)
        end
      end
    end

    context 'when sorting by name (default)' do
      it 'sorts branches by name ascending' do
        expect(branches.first.name).to eq("'test'")
      end
    end

    context 'when sorting by name shorthand' do
      let(:params) { { sort: 'name' } }

      it 'normalizes to name_asc and sorts branches by name ascending' do
        expect(branches.first.name).to eq("'test'")
      end
    end

    context 'when sorting by name descending' do
      let(:params) { { sort: 'name_desc' } }

      it 'sorts branches by name descending' do
        expect(branches.first.name).to eq('Ääh-test-utf-8')
      end
    end

    context 'when sorting by updated descending' do
      let(:params) { { sort: 'updated_desc' } }
      let(:include_commits) { true }

      it 'sorts branches by commit date descending' do
        first_date = branches.first.dereferenced_target.committed_date
        second_date = branches.second.dereferenced_target.committed_date
        expect(first_date).to be >= second_date
      end
    end

    context 'when sorting by updated ascending' do
      let(:params) { { sort: 'updated_asc' } }

      it 'sorts branches by commit date ascending' do
        expect(branches.first.name).to eq('feature')
      end
    end

    context 'when searching by substring' do
      let(:params) { { search: 'fix' } }

      it 'returns matching branches' do
        expect(branches.map(&:name)).to eq(['fix'])
      end
    end

    context 'when searching is case-insensitive' do
      let(:params) { { search: 'FIX' } }

      it 'matches branches regardless of case' do
        expect(branches.map(&:name)).to eq(['fix'])
      end
    end

    context 'when searching with mixed case' do
      let(:params) { { search: 'Feature' } }

      it 'returns case-insensitive matches with exact match first' do
        expect(branches.first.name).to eq('feature')
        expect(branches.second.name).to eq('feature_conflict')
      end
    end

    context 'when searching by substring with multiple matches' do
      let(:params) { { search: 'add' } }

      it 'returns all branches containing the term' do
        branches.each { |b| expect(b.name).to include('add') }
        expect(branches.count).to eq(5)
      end
    end

    context 'when searching with exact match' do
      let(:params) { { search: 'feature' } }

      it 'returns exact match first' do
        expect(branches.first.name).to eq('feature')
        expect(branches.second.name).to eq('feature_conflict')
      end
    end

    context 'with ^ operator (starts with)' do
      let(:params) { { search: '^feature' } }

      it 'returns branches starting with the term' do
        branches.each { |b| expect(b.name).to start_with('feature') }
        expect(branches.count).to eq(2)
      end
    end

    context 'with $ operator (ends with)' do
      let(:params) { { search: 'feature$' } }

      it 'returns branches ending with the term' do
        expect(branches.map(&:name)).to eq(['feature'])
      end
    end

    context 'with * operator (wildcard)' do
      let(:params) { { search: 'f*e' } }

      it 'returns branches matching the pattern' do
        expect(branches.first.name).to eq('2-mb-file')
        expect(branches.count).to eq(30)
      end
    end

    context 'with multiple wildcards' do
      let(:params) { { search: 'f*a*e' } }

      it 'returns branches matching the pattern' do
        expect(branches.first.name).to eq('after-create-delete-modify-move')
        expect(branches.count).to eq(11)
      end
    end

    context 'with combined operators' do
      let(:params) { { search: '^f*e$' } }

      it 'returns branches matching the pattern' do
        expect(branches.first.name).to eq('feature')
      end
    end

    context 'with ^...$ operator (exact match)' do
      let(:params) { { search: '^feature$' } }

      it 'returns only the exact matching branch' do
        expect(branches.map(&:name)).to eq(['feature'])
      end
    end

    context 'with ^...$ operator (exact match, no results)' do
      let(:params) { { search: '^nonexistent$' } }

      it 'returns empty array' do
        expect(branches).to be_empty
      end
    end

    context 'with no matches' do
      let(:params) { { search: 'nonexistent' } }

      it 'returns empty array' do
        expect(branches).to be_empty
      end
    end

    context 'with per_page' do
      let(:params) { { per_page: 2 } }

      it 'limits results' do
        expect(branches.count).to eq(2)
      end
    end

    context 'with page_token' do
      it 'returns results after the cursor from first page' do
        first_finder = described_class.new(repository, { per_page: 2 })
        first_page = first_finder.execute

        second_finder = described_class.new(repository, { page_token: first_finder.next_cursor, per_page: 2 })
        second_page = second_finder.execute

        expect(second_page.count).to eq(2)
        expect(second_page.map(&:name)).not_to include(*first_page.map(&:name))
      end
    end

    context 'with sort and pagination' do
      let(:params) { { sort: 'updated_asc', per_page: 5 } }

      it 'applies both sort and pagination' do
        expect(branches.map(&:name)).to eq(%w[feature improve/awesome merge-test markdown feature_conflict])
      end
    end

    context 'with sort, pagination and page_token' do
      let(:first_finder) { described_class.new(repository, { sort: 'updated_asc', per_page: 2 }) }
      let(:params) { { sort: 'updated_asc', page_token: first_finder.tap(&:execute).next_cursor, per_page: 2 } }

      it 'returns next page with sort' do
        expect(branches.map(&:name)).to eq(%w[merge-test markdown])
      end
    end

    context 'with search and pagination' do
      let(:params) { { search: '^f', per_page: 2 } }

      it 'applies search with pagination' do
        expect(branches.map(&:name)).to eq(%w[feature feature_conflict])
      end
    end

    context 'with search and sort' do
      let(:params) { { sort: 'updated_desc', search: 'feature' } }

      it 'returns exact match first even with sort' do
        expect(branches.first.name).to eq('feature')
        expect(branches.second.name).to eq('feature_conflict')
        expect(branches.count).to eq(2)
      end
    end

    context 'with page parameter' do
      let(:params) { { per_page: 5, page: 2 } }

      it 'fetches per_page * page records to support offset pagination' do
        expect(branches.count).to eq(10)
      end
    end

    context 'with page parameter and include_commits' do
      let(:include_commits) { true }
      let(:params) { { per_page: 5, page: 2 } }

      it 'only hydrates commits for the target page branches' do
        results = finder.execute

        # First 5 branches (page 1) should not have commits loaded
        results[0, 5].each do |branch|
          expect(branch.dereferenced_target).to be_nil
        end

        # Last 5 branches (page 2, the target page) should have commits
        results[5, 5].each do |branch|
          expect(branch.dereferenced_target).to be_present
        end
      end
    end

    context 'with page 1' do
      let(:params) { { per_page: 5, page: 1 } }

      it 'fetches per_page records' do
        expect(branches.count).to eq(5)
      end
    end

    context 'with page_token and page' do
      it 'ignores page and uses per_page as-is when page_token is present' do
        first_finder = described_class.new(repository, { per_page: 2 })
        first_finder.execute

        finder_with_both = described_class.new(repository,
          { per_page: 2, page: 3, page_token: first_finder.next_cursor })
        result = finder_with_both.execute

        expect(result.count).to eq(2)
      end
    end
  end

  describe '#next_cursor' do
    subject(:next_cursor) { finder.next_cursor }

    it 'is nil before execute' do
      expect(next_cursor).to be_nil
    end

    context 'when execute has been called' do
      before do
        finder.execute
      end

      context 'without pagination' do
        it 'returns nil when all results fit in one page' do
          expect(next_cursor).to be_nil
        end
      end

      context 'with pagination' do
        let(:params) { { per_page: 2 } }

        it 'returns the Gitaly pagination cursor' do
          expect(next_cursor).to be_present
        end

        it 'can be used as page_token for the next page' do
          next_finder = described_class.new(repository, { per_page: 2, page_token: next_cursor })
          next_page = next_finder.execute

          expect(next_page).to be_present
          expect(next_page.count).to eq(2)
        end
      end

      context 'with empty results' do
        let(:params) { { search: 'nonexistent' } }

        it 'returns nil' do
          expect(next_cursor).to be_nil
        end
      end
    end
  end

  describe '#total' do
    subject(:total) { finder.total }

    it 'returns the branch count' do
      expect(total).to be_an(Integer)
      expect(total).to eq(repository.branch_count)
    end
  end
end
