# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Search::GroupService, feature_category: :global_search do
  shared_examples_for 'group search' do
    context 'finding projects by name' do
      let(:user) { create(:user) }
      let(:term) { "Project Name" }
      let(:nested_group) { create(:group, :nested) }

      # These projects shouldn't be found
      let!(:outside_project) { create(:project, :public, name: "Outside #{term}") }
      let!(:private_project) { create(:project, :private, namespace: nested_group, name: "Private #{term}") }
      let!(:other_project)   { create(:project, :public, namespace: nested_group, name: term.reverse) }

      # These projects should be found
      let!(:project1) { create(:project, :internal, namespace: nested_group, name: "Inner #{term} 1") }
      let!(:project2) { create(:project, :internal, namespace: nested_group, name: "Inner #{term} 2") }
      let!(:project3) { create(:project, :internal, namespace: nested_group.parent, name: "Outer #{term}") }

      let(:results) { described_class.new(user, search_group, search: term).execute }

      subject { results.objects('projects') }

      context 'in parent group' do
        let(:search_group) { nested_group.parent }

        it { is_expected.to match_array([project1, project2, project3]) }
      end

      context 'in subgroup' do
        let(:search_group) { nested_group }

        it { is_expected.to match_array([project1, project2]) }
      end
    end
  end

  describe 'basic search' do
    include_examples 'group search'
  end

  context 'issues' do
    let(:scope) { 'issues' }

    context 'sorting' do
      let_it_be(:group) { create(:group) }
      let_it_be(:project) { create(:project, :public, group: group) }

      let!(:old_result) { create(:issue, project: project, title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:issue, project: project, title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:issue, project: project, title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:issue, project: project, title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:issue, project: project, title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:issue, project: project, title: 'updated very old', updated_at: 1.year.ago) }

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(nil, group, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(nil, group, search: 'updated', sort: sort).execute }
      end
    end
  end

  context 'merge requests' do
    let(:scope) { 'merge_requests' }

    context 'sorting' do
      let!(:group) { create(:group) }
      let!(:project) { create(:project, :public, group: group) }

      let!(:old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'old-1', title: 'sorted old', created_at: 1.month.ago) }
      let!(:new_result) { create(:merge_request, :opened, source_project: project, source_branch: 'new-1', title: 'sorted recent', created_at: 1.day.ago) }
      let!(:very_old_result) { create(:merge_request, :opened, source_project: project, source_branch: 'very-old-1', title: 'sorted very old', created_at: 1.year.ago) }

      let!(:old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-old-1', title: 'updated old', updated_at: 1.month.ago) }
      let!(:new_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-new-1', title: 'updated recent', updated_at: 1.day.ago) }
      let!(:very_old_updated) { create(:merge_request, :opened, source_project: project, source_branch: 'updated-very-old-1', title: 'updated very old', updated_at: 1.year.ago) }

      include_examples 'search results sorted' do
        let(:results_created) { described_class.new(nil, group, search: 'sorted', sort: sort).execute }
        let(:results_updated) { described_class.new(nil, group, search: 'updated', sort: sort).execute }
      end
    end
  end
end
