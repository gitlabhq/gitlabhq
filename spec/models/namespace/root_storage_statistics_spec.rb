# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::RootStorageStatistics, type: :model do
  it { is_expected.to belong_to :namespace }
  it { is_expected.to have_one(:route).through(:namespace) }

  it { is_expected.to delegate_method(:all_projects).to(:namespace) }

  context 'scopes' do
    describe '.for_namespace_ids' do
      it 'returns only requested namespaces' do
        stats = create_list(:namespace_root_storage_statistics, 3)
        namespace_ids = stats[0..1].map { |s| s.namespace_id }

        requested_stats = described_class.for_namespace_ids(namespace_ids).pluck(:namespace_id)

        expect(requested_stats).to eq(namespace_ids)
      end
    end
  end

  describe '#recalculate!' do
    let(:namespace) { create(:group) }
    let(:root_storage_statistics) { create(:namespace_root_storage_statistics, namespace: namespace) }

    let(:project1) { create(:project, namespace: namespace) }
    let(:project2) { create(:project, namespace: namespace) }

    let!(:stat1) { create(:project_statistics, project: project1, with_data: true, size_multiplier: 100) }
    let!(:stat2) { create(:project_statistics, project: project2, with_data: true, size_multiplier: 200) }

    shared_examples 'data refresh' do
      it 'aggregates project statistics' do
        root_storage_statistics.recalculate!

        root_storage_statistics.reload

        total_repository_size = stat1.repository_size + stat2.repository_size
        total_wiki_size = stat1.wiki_size + stat2.wiki_size
        total_lfs_objects_size = stat1.lfs_objects_size + stat2.lfs_objects_size
        total_build_artifacts_size = stat1.build_artifacts_size + stat2.build_artifacts_size
        total_packages_size = stat1.packages_size + stat2.packages_size
        total_storage_size = stat1.storage_size + stat2.storage_size
        total_snippets_size = stat1.snippets_size + stat2.snippets_size
        total_pipeline_artifacts_size = stat1.pipeline_artifacts_size + stat2.pipeline_artifacts_size
        total_uploads_size = stat1.uploads_size + stat2.uploads_size

        expect(root_storage_statistics.repository_size).to eq(total_repository_size)
        expect(root_storage_statistics.wiki_size).to eq(total_wiki_size)
        expect(root_storage_statistics.lfs_objects_size).to eq(total_lfs_objects_size)
        expect(root_storage_statistics.build_artifacts_size).to eq(total_build_artifacts_size)
        expect(root_storage_statistics.packages_size).to eq(total_packages_size)
        expect(root_storage_statistics.storage_size).to eq(total_storage_size)
        expect(root_storage_statistics.snippets_size).to eq(total_snippets_size)
        expect(root_storage_statistics.pipeline_artifacts_size).to eq(total_pipeline_artifacts_size)
        expect(root_storage_statistics.uploads_size).to eq(total_uploads_size)
      end

      it 'works when there are no projects' do
        Project.delete_all

        root_storage_statistics.recalculate!

        root_storage_statistics.reload
        expect(root_storage_statistics.repository_size).to eq(0)
        expect(root_storage_statistics.wiki_size).to eq(0)
        expect(root_storage_statistics.lfs_objects_size).to eq(0)
        expect(root_storage_statistics.build_artifacts_size).to eq(0)
        expect(root_storage_statistics.packages_size).to eq(0)
        expect(root_storage_statistics.storage_size).to eq(0)
        expect(root_storage_statistics.snippets_size).to eq(0)
        expect(root_storage_statistics.pipeline_artifacts_size).to eq(0)
      end
    end

    shared_examples 'does not include personal snippets' do
      specify do
        expect(root_storage_statistics).not_to receive(:from_personal_snippets)

        root_storage_statistics.recalculate!
      end
    end

    it_behaves_like 'data refresh'
    it_behaves_like 'does not include personal snippets'

    context 'with subgroups' do
      let(:subgroup1) { create(:group, parent: namespace)}
      let(:subgroup2) { create(:group, parent: subgroup1)}

      let(:project1) { create(:project, namespace: subgroup1) }
      let(:project2) { create(:project, namespace: subgroup2) }

      it_behaves_like 'data refresh'
      it_behaves_like 'does not include personal snippets'
    end

    context 'with a personal namespace' do
      let_it_be(:user) { create(:user) }

      let(:namespace) { user.namespace }

      it_behaves_like 'data refresh'

      context 'when user has personal snippets' do
        let(:total_project_snippets_size) { stat1.snippets_size + stat2.snippets_size }

        it 'aggregates personal and project snippets size' do
          # This is just a a snippet authored by other user
          # to ensure we only pick snippets from the namespace
          # user
          create(:personal_snippet, :repository).statistics.refresh!

          snippets = create_list(:personal_snippet, 3, :repository, author: user)
          snippets.each { |s| s.statistics.refresh! }

          total_personal_snippets_size = snippets.map { |s| s.statistics.repository_size }.sum

          root_storage_statistics.recalculate!

          expect(root_storage_statistics.snippets_size).to eq(total_personal_snippets_size + total_project_snippets_size)
        end

        context 'when personal snippets do not have statistics' do
          it 'does not raise any error' do
            snippets = create_list(:personal_snippet, 2, :repository, author: user)
            snippets.last.statistics.refresh!

            root_storage_statistics.recalculate!

            expect(root_storage_statistics.snippets_size).to eq(total_project_snippets_size + snippets.last.statistics.repository_size)
          end
        end
      end
    end
  end
end
