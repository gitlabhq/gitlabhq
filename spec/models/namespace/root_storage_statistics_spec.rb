# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespace::RootStorageStatistics, type: :model, feature_category: :consumables_cost_management do
  it { is_expected.to belong_to :namespace }
  it { is_expected.to have_one(:route).through(:namespace) }

  it { is_expected.to delegate_method(:all_projects_except_soft_deleted).to(:namespace) }

  context 'scopes' do
    describe '.for_namespace_ids' do
      it 'returns only requested namespaces' do
        stats = create_list(:namespace_root_storage_statistics, 3)
        namespace_ids = stats[0..1].map(&:namespace_id)

        requested_stats = described_class.for_namespace_ids(namespace_ids).pluck(:namespace_id)

        expect(requested_stats).to eq(namespace_ids)
      end
    end
  end

  describe '#recalculate!' do
    let_it_be(:namespace) { create(:group) }

    let(:root_storage_statistics) { create(:namespace_root_storage_statistics, namespace: namespace) }

    let(:project1) { create(:project, namespace: namespace) }
    let(:project2) { create(:project, namespace: namespace) }
    let(:project3) { create(:project, namespace: namespace, marked_for_deletion_at: 1.day.ago, pending_delete: true) }

    shared_examples 'project data refresh' do
      it 'aggregates eligible project statistics' do
        root_storage_statistics.recalculate!

        root_storage_statistics.reload

        total_repository_size = project_stat1.repository_size + project_stat2.repository_size
        total_wiki_size = project_stat1.wiki_size + project_stat2.wiki_size
        total_lfs_objects_size = project_stat1.lfs_objects_size + project_stat2.lfs_objects_size
        total_build_artifacts_size = project_stat1.build_artifacts_size + project_stat2.build_artifacts_size
        total_packages_size = project_stat1.packages_size + project_stat2.packages_size
        total_storage_size = project_stat1.reload.storage_size + project_stat2.reload.storage_size
        total_snippets_size = project_stat1.snippets_size + project_stat2.snippets_size
        total_pipeline_artifacts_size = project_stat1.pipeline_artifacts_size + project_stat2.pipeline_artifacts_size
        total_uploads_size = project_stat1.uploads_size + project_stat2.uploads_size

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

      it 'aggregates container_repositories_size and storage_size' do
        allow(namespace).to receive(:container_repositories_size).and_return(999)

        root_storage_statistics.recalculate!

        root_storage_statistics.reload

        total_storage_size = project_stat1.reload.storage_size + project_stat2.reload.storage_size + 999

        expect(root_storage_statistics.container_registry_size).to eq(999)
        expect(root_storage_statistics.storage_size).to eq(total_storage_size)
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

    context 'with project statistics' do
      let!(:project_stat1) { create(:project_statistics, project: project1, with_data: true, size_multiplier: 100) }
      let!(:project_stat2) { create(:project_statistics, project: project2, with_data: true, size_multiplier: 200) }
      let!(:project_stat3) { create(:project_statistics, project: project3, with_data: true, size_multiplier: 300) }

      it_behaves_like 'project data refresh'
      it_behaves_like 'does not include personal snippets'
    end

    context 'with subgroups' do
      let(:subgroup1) { create(:group, parent: namespace) }
      let(:subgroup2) { create(:group, parent: subgroup1) }

      let(:project1) { create(:project, namespace: subgroup1) }
      let(:project2) { create(:project, namespace: subgroup2) }

      let!(:project_stat1) { create(:project_statistics, project: project1, with_data: true, size_multiplier: 100) }
      let!(:project_stat2) { create(:project_statistics, project: project2, with_data: true, size_multiplier: 200) }

      it_behaves_like 'project data refresh'
      it_behaves_like 'does not include personal snippets'
    end

    context 'with a group namespace' do
      let_it_be(:root_group) { create(:group) }
      let_it_be(:group1) { create(:group, parent: root_group) }
      let_it_be(:subgroup1) { create(:group, parent: group1) }
      let_it_be(:group2) { create(:group, parent: root_group) }
      let_it_be(:root_namespace_stat) do
        create(:namespace_statistics, namespace: root_group, storage_size: 100, dependency_proxy_size: 100)
      end

      let_it_be(:group1_namespace_stat) do
        create(:namespace_statistics, namespace: group1, storage_size: 200, dependency_proxy_size: 200)
      end

      let_it_be(:group2_namespace_stat) do
        create(:namespace_statistics, namespace: group2, storage_size: 300, dependency_proxy_size: 300)
      end

      let_it_be(:subgroup1_namespace_stat) do
        create(:namespace_statistics, namespace: subgroup1, storage_size: 300, dependency_proxy_size: 100)
      end

      let(:namespace) { root_group }

      let!(:project_stat1) { create(:project_statistics, project: project1, with_data: true, size_multiplier: 100) }
      let!(:project_stat2) { create(:project_statistics, project: project2, with_data: true, size_multiplier: 200) }

      it 'aggregates namespace statistics' do
        # This group is not a descendant of the root_group so it shouldn't be included in the final stats.
        other_group = create(:group)
        create(:namespace_statistics, namespace: other_group, storage_size: 500, dependency_proxy_size: 500)

        root_storage_statistics.recalculate!

        total_repository_size = project_stat1.repository_size + project_stat2.repository_size
        total_lfs_objects_size = project_stat1.lfs_objects_size + project_stat2.lfs_objects_size
        total_build_artifacts_size = project_stat1.build_artifacts_size + project_stat2.build_artifacts_size
        total_packages_size = project_stat1.packages_size + project_stat2.packages_size
        total_snippets_size = project_stat1.snippets_size + project_stat2.snippets_size
        total_pipeline_artifacts_size = project_stat1.pipeline_artifacts_size + project_stat2.pipeline_artifacts_size
        total_uploads_size = project_stat1.uploads_size + project_stat2.uploads_size
        total_wiki_size = project_stat1.wiki_size + project_stat2.wiki_size
        total_dependency_proxy_size = root_namespace_stat.dependency_proxy_size +
          group1_namespace_stat.dependency_proxy_size + group2_namespace_stat.dependency_proxy_size +
          subgroup1_namespace_stat.dependency_proxy_size
        total_storage_size = project_stat1.reload.storage_size + project_stat2.reload.storage_size +
          root_namespace_stat.storage_size + group1_namespace_stat.storage_size +
          group2_namespace_stat.storage_size + subgroup1_namespace_stat.storage_size

        expect(root_storage_statistics.repository_size).to eq(total_repository_size)
        expect(root_storage_statistics.lfs_objects_size).to eq(total_lfs_objects_size)
        expect(root_storage_statistics.build_artifacts_size).to eq(total_build_artifacts_size)
        expect(root_storage_statistics.packages_size).to eq(total_packages_size)
        expect(root_storage_statistics.snippets_size).to eq(total_snippets_size)
        expect(root_storage_statistics.pipeline_artifacts_size).to eq(total_pipeline_artifacts_size)
        expect(root_storage_statistics.uploads_size).to eq(total_uploads_size)
        expect(root_storage_statistics.dependency_proxy_size).to eq(total_dependency_proxy_size)
        expect(root_storage_statistics.wiki_size).to eq(total_wiki_size)
        expect(root_storage_statistics.storage_size).to eq(total_storage_size)
      end

      it 'works when there are no namespace statistics' do
        NamespaceStatistics.delete_all

        root_storage_statistics.recalculate!

        total_storage_size = project_stat1.reload.storage_size + project_stat2.reload.storage_size

        expect(root_storage_statistics.storage_size).to eq(total_storage_size)
      end
    end

    context 'with a personal namespace' do
      let_it_be(:user) { create(:user) }

      let(:namespace) { user.namespace }

      let!(:project_stat1) { create(:project_statistics, project: project1, with_data: true, size_multiplier: 100) }
      let!(:project_stat2) { create(:project_statistics, project: project2, with_data: true, size_multiplier: 200) }

      it_behaves_like 'project data refresh'

      it 'does not aggregate namespace statistics' do
        create(:namespace_statistics, namespace: user.namespace, storage_size: 200, dependency_proxy_size: 200)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.storage_size)
          .to eq(project_stat1.reload.storage_size + project_stat2.reload.storage_size)
        expect(root_storage_statistics.dependency_proxy_size).to eq(0)
      end

      context 'when user has personal snippets' do
        let(:total_project_snippets_size) { project_stat1.snippets_size + project_stat2.snippets_size }

        it 'aggregates personal and project snippets size' do
          # This is just a a snippet authored by other user
          # to ensure we only pick snippets from the namespace
          # user
          create(:personal_snippet, :repository).statistics.refresh!

          snippets = create_list(:personal_snippet, 3, :repository, author: user)
          snippets.each { |s| s.statistics.refresh! }

          total_personal_snippets_size = snippets.sum { |s| s.statistics.repository_size }

          root_storage_statistics.recalculate!

          total = total_personal_snippets_size + total_project_snippets_size
          expect(root_storage_statistics.snippets_size).to eq(total)
        end

        context 'when personal snippets do not have statistics' do
          it 'does not raise any error' do
            snippets = create_list(:personal_snippet, 2, :repository, author: user)
            snippets.last.statistics.refresh!

            root_storage_statistics.recalculate!

            total = total_project_snippets_size + snippets.last.statistics.repository_size
            expect(root_storage_statistics.snippets_size).to eq(total)
          end
        end
      end
    end

    context 'with forks of projects' do
      it 'aggregates total private forks size' do
        project = create_project(visibility_level: :private, size_multiplier: 150)
        project_fork = create_fork(project, size_multiplier: 100)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.private_forks_storage_size)
          .to eq(project_fork.statistics.reload.storage_size)
      end

      it 'aggregates total public forks size' do
        project = create_project(visibility_level: :public, size_multiplier: 250)
        project_fork = create_fork(project, size_multiplier: 200)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.public_forks_storage_size)
          .to eq(project_fork.statistics.reload.storage_size)
      end

      it 'aggregates total internal forks size' do
        project = create_project(visibility_level: :internal, size_multiplier: 70)
        project_fork = create_fork(project, size_multiplier: 50)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.internal_forks_storage_size)
          .to eq(project_fork.statistics.reload.storage_size)
      end

      it 'aggregates multiple forks' do
        project = create_project(size_multiplier: 175)
        fork_a = create_fork(project, size_multiplier: 50)
        fork_b = create_fork(project, size_multiplier: 60)

        root_storage_statistics.recalculate!

        total_size = fork_a.statistics.reload.storage_size + fork_b.statistics.reload.storage_size
        expect(root_storage_statistics.reload.private_forks_storage_size).to eq(total_size)
      end

      it 'aggregates only forks in the namespace' do
        other_namespace = create(:group)
        project = create_project(size_multiplier: 175)
        fork_a = create_fork(project, size_multiplier: 50)
        create_fork(project, size_multiplier: 50, namespace: other_namespace)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.private_forks_storage_size).to eq(fork_a.statistics.reload.storage_size)
      end

      it 'aggregates forks in subgroups' do
        subgroup = create(:group, parent: namespace)
        project = create_project(size_multiplier: 100)
        project_fork = create_fork(project, namespace: subgroup, size_multiplier: 300)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.private_forks_storage_size)
          .to eq(project_fork.statistics.reload.storage_size)
      end

      it 'aggregates forks along with total storage size' do
        project = create_project(size_multiplier: 240)
        project_fork = create_fork(project, size_multiplier: 100)

        root_storage_statistics.recalculate!

        root_storage_statistics.reload
        expect(root_storage_statistics.private_forks_storage_size).to eq(project_fork.statistics.reload.storage_size)

        total = project.statistics.storage_size + project_fork.statistics.reload.storage_size
        expect(root_storage_statistics.storage_size).to eq(total)
      end

      it 'sets the public forks storage size back to zero' do
        root_storage_statistics.update!(public_forks_storage_size: 200)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.public_forks_storage_size).to eq(0)
      end

      it 'sets the private forks storage size back to zero' do
        root_storage_statistics.update!(private_forks_storage_size: 100)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.private_forks_storage_size).to eq(0)
      end

      it 'sets the internal forks storage size back to zero' do
        root_storage_statistics.update!(internal_forks_storage_size: 50)

        root_storage_statistics.recalculate!

        expect(root_storage_statistics.reload.internal_forks_storage_size).to eq(0)
      end
    end
  end

  def create_project(size_multiplier:, visibility_level: :private)
    project = create(:project, visibility_level, namespace: namespace)
    create(:project_statistics, project: project, with_data: true, size_multiplier: size_multiplier)

    project
  end

  def create_fork(project, size_multiplier:, namespace: nil)
    fork_namespace = namespace || project.namespace
    project_fork = create(:project, namespace: fork_namespace, visibility_level: project.visibility_level)
    create(:project_statistics, project: project_fork, with_data: true, size_multiplier: size_multiplier)
    fork_network = project.fork_network || (create(:fork_network, root_project: project) && project.reload.fork_network)
    create(:fork_network_member, project: project_fork, fork_network: fork_network)

    project_fork
  end
end
