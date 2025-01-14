# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::PendingBuild, feature_category: :continuous_integration do
  let_it_be_with_refind(:project) { create(:project) }
  let_it_be_with_refind(:pipeline) { create(:ci_pipeline, project: project) }

  let(:build) { create(:ci_build, :created, pipeline: pipeline) }

  describe 'associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to belong_to :build }
    it { is_expected.to belong_to :namespace }
  end

  describe 'scopes' do
    describe '.with_instance_runners' do
      subject(:pending_builds) { described_class.with_instance_runners }

      let!(:pending_build_1) { create(:ci_pending_build, instance_runners_enabled: false) }

      context 'when pending builds cannot be picked up by runner' do
        it 'returns an empty collection of pending builds' do
          expect(pending_builds).to be_empty
        end
      end

      context 'when pending builds can be picked up by runner' do
        let!(:pending_build_2) { create(:ci_pending_build) }

        it 'returns matching pending builds' do
          expect(pending_builds).to contain_exactly(pending_build_2)
        end
      end
    end

    describe '.for_tags' do
      subject(:pending_builds) { described_class.for_tags(tag_ids) }

      let_it_be(:pending_build_with_tags) { create(:ci_pending_build, tag_ids: [1, 2]) }
      let_it_be(:pending_build_without_tags) { create(:ci_pending_build) }

      context 'when tag_ids match pending builds' do
        let(:tag_ids) { [1, 2] }

        it 'returns matching pending builds' do
          expect(pending_builds).to contain_exactly(pending_build_with_tags, pending_build_without_tags)
        end
      end

      context 'when tag_ids does not match pending builds' do
        let(:tag_ids) { [non_existing_record_id] }

        it 'returns matching pending builds without tags' do
          expect(pending_builds).to contain_exactly(pending_build_without_tags)
        end
      end

      context 'when tag_ids is not provided' do
        context 'with a nil value' do
          let(:tag_ids) { nil }

          it 'returns matching pending builds without tags' do
            expect(pending_builds).to contain_exactly(pending_build_without_tags)
          end
        end

        context 'with an empty array' do
          let(:tag_ids) { [] }

          it 'returns matching pending builds without tags' do
            expect(pending_builds).to contain_exactly(pending_build_without_tags)
          end
        end
      end
    end
  end

  describe '.upsert_from_build!' do
    context 'another pending entry does not exist' do
      it 'creates a new pending entry' do
        result = described_class.upsert_from_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
        expect(build.reload.queuing_entry).to be_present
      end
    end

    context 'when another queuing entry exists for given build' do
      before do
        create(:ci_pending_build, build: build, project: project)
      end

      it 'returns a build id as a result' do
        result = described_class.upsert_from_build!(build)

        expect(result.rows.dig(0, 0)).to eq build.id
      end
    end

    context 'when project does not have shared runners enabled' do
      before do
        project.update!(shared_runners_enabled: false)
      end

      it 'sets instance_runners_enabled to false' do
        described_class.upsert_from_build!(build)

        expect(described_class.last.instance_runners_enabled).to be_falsey
      end
    end

    context 'when project has shared runner' do
      let_it_be(:runner) { create(:ci_runner, :instance) }

      before do
        project.update!(shared_runners_enabled: true)
      end

      it 'sets instance_runners_enabled to true' do
        described_class.upsert_from_build!(build)

        expect(described_class.last.instance_runners_enabled).to be_truthy
      end

      context 'when project is about to be deleted' do
        before do
          project.update!(pending_delete: true)
        end

        it 'sets instance_runners_enabled to false' do
          described_class.upsert_from_build!(build)

          expect(described_class.last.instance_runners_enabled).to be_falsey
        end
      end

      context 'when builds are disabled' do
        before do
          project.project_feature.update!(builds_access_level: false)
        end

        it 'sets instance_runners_enabled to false' do
          described_class.upsert_from_build!(build)

          expect(described_class.last.instance_runners_enabled).to be_falsey
        end
      end
    end

    context 'when build has tags' do
      let!(:build) { create(:ci_build, :tags) }

      subject(:ci_pending_build) { described_class.last }

      it 'sets tag_ids' do
        described_class.upsert_from_build!(build)

        expect(ci_pending_build.tag_ids).to eq(build.tags_ids)
      end
    end

    context 'when a build project is nested in a subgroup' do
      let_it_be(:group) { create(:group, :with_hierarchy, depth: 2, children: 1) }
      let_it_be_with_refind(:project) { create(:project, namespace: group.descendants.first) }
      let_it_be_with_refind(:pipeline) { create(:ci_pipeline, project: project) }

      let(:build) { create(:ci_build, :created, pipeline: pipeline) }

      subject(:latest_pending_build) { described_class.last }

      context 'when build can be picked by a group runner' do
        before do
          project.update!(group_runners_enabled: true)
        end

        it 'denormalizes namespace traversal ids' do
          described_class.upsert_from_build!(build)

          expect(latest_pending_build.namespace_traversal_ids).not_to be_empty
          expect(latest_pending_build.namespace_traversal_ids).to eq [group.id, project.namespace.id]
        end
      end

      context 'when build can not be picked by a group runner' do
        before do
          project.update!(group_runners_enabled: false)
        end

        it 'creates an empty namespace traversal ids array' do
          described_class.upsert_from_build!(build)

          expect(latest_pending_build.namespace_traversal_ids).to be_empty
        end
      end
    end
  end

  describe '.namespace_transfer_params' do
    let(:group) { create(:group) }
    let(:new_parent_group) { create(:group) }
    let(:expected_transfer_params) do
      {
        namespace_traversal_ids: [new_parent_group.id, group.id],
        namespace_id: group.id
      }
    end

    it 'updates all pending builds with namespace_transfer_params', :aggregate_failures do
      expect do
        group.update!(parent: new_parent_group)
        # reload is called to make sure traversal_ids are reloaded
      end.to change { Ci::PendingBuild.namespace_transfer_params(group.reload) }.to(expected_transfer_params)
        .and not_change { Ci::PendingBuild.namespace_transfer_params(new_parent_group.reload) }
    end
  end

  describe 'partitioning' do
    include Ci::PartitioningHelpers

    before do
      stub_current_partition_id(ci_testing_partition_id)
    end

    let(:new_pipeline) { create(:ci_pipeline, project: pipeline.project) }
    let(:new_build) { create(:ci_build, pipeline: new_pipeline) }

    it 'assigns the same partition id as the one that build has', :aggregate_failures do
      expect(new_build.partition_id).to eq ci_testing_partition_id

      described_class.upsert_from_build!(build)
      described_class.upsert_from_build!(new_build)

      expect(build.reload.queuing_entry.partition_id).to eq pipeline.partition_id
      expect(new_build.reload.queuing_entry.partition_id).to eq ci_testing_partition_id
    end
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:namespace) }
    let!(:model) { create(:ci_pending_build, namespace: parent) }
  end

  it_behaves_like 'cleanup by a loose foreign key' do
    let!(:parent) { create(:project) }
    let!(:model) { create(:ci_pending_build, project: parent) }
  end
end
