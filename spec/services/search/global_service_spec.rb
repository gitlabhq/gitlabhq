# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::GlobalService, feature_category: :global_search do
  let_it_be(:user) { create(:user) }
  let_it_be(:internal_user) { create(:user) }

  let_it_be(:found_project)    { create(:project, :private, name: 'searchable_project', maintainers: user) }
  let_it_be(:unfound_project)  { create(:project, :private, name: 'unfound_project') }
  let_it_be(:internal_project) { create(:project, :internal, name: 'searchable_internal_project') }
  let_it_be(:public_project)   { create(:project, :public, name: 'searchable_public_project') }
  let_it_be(:archived_project) { create(:project, :public, archived: true, name: 'archived_project') }

  describe '#execute' do
    context 'unauthenticated' do
      it 'returns public projects only' do
        results = described_class.new(nil, search: "searchable").execute

        expect(results.objects('projects')).to match_array [public_project]
      end
    end

    context 'authenticated' do
      it 'returns public, internal and private projects' do
        results = described_class.new(user, search: "searchable").execute

        expect(results.objects('projects')).to match_array [public_project, found_project, internal_project]
      end

      it 'returns only public & internal projects' do
        results = described_class.new(internal_user, search: "searchable").execute

        expect(results.objects('projects')).to match_array [internal_project, public_project]
      end

      it 'project name is searchable' do
        results = described_class.new(user, search: found_project.name).execute

        expect(results.objects('projects')).to match_array [found_project]
      end

      it 'does not return archived projects' do
        results = described_class.new(user, search: "archived").execute

        expect(results.objects('projects')).not_to include(archived_project)
      end

      it 'returns archived projects if the include_archived option is passed' do
        results = described_class.new(user, { include_archived: true, search: "archived" }).execute

        expect(results.objects('projects')).to include(archived_project)
      end
    end
  end

  context 'issues' do
    let(:scope) { 'issues' }

    context 'sorting' do
      let_it_be(:project) { create(:project, :public) }

      let!(:old_result) { create(:issue, project: project, title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:issue, project: project, title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:issue, project: project, title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:issue, project: project, title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:issue, project: project, title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:issue, project: project, title: 'updated very old', updated_at: 1.year.ago) }

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(nil, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(nil, search: 'updated', sort: sort).execute }
      end
    end
  end

  context 'merge_request' do
    let(:scope) { 'merge_requests' }

    context 'sorting' do
      let!(:project) { create(:project, :public) }

      let!(:old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'old-1', title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:merge_request, :opened, source_project: project, source_branch: 'new-1', title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'very-old-1', title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-old-1', title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-new-1', title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-very-old-1', title: 'updated very old', updated_at: 1.year.ago) }

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(nil, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(nil, search: 'updated', sort: sort).execute }
      end
    end
  end
end
