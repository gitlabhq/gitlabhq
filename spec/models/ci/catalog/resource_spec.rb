# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  include_context 'when there are catalog resources with versions'

  it { is_expected.to belong_to(:project) }

  it do
    is_expected.to(
      have_many(:components).class_name('Ci::Catalog::Resources::Component').with_foreign_key(:catalog_resource_id))
  end

  it do
    is_expected.to(
      have_many(:versions).class_name('Ci::Catalog::Resources::Version').with_foreign_key(:catalog_resource_id))
  end

  it { is_expected.to delegate_method(:avatar_path).to(:project) }
  it { is_expected.to delegate_method(:star_count).to(:project) }

  it { is_expected.to define_enum_for(:state).with_values({ draft: 0, published: 1 }) }

  describe '.for_projects' do
    it 'returns catalog resources for the given project IDs' do
      resources_for_projects = described_class.for_projects(project1.id)

      expect(resources_for_projects).to contain_exactly(resource1)
    end
  end

  describe '.search' do
    it 'returns catalog resources whose name or description match the search term' do
      resources = described_class.search('Z')

      expect(resources).to contain_exactly(resource2, resource3)
    end
  end

  describe '.order_by_created_at_desc' do
    it 'returns catalog resources sorted by descending created at' do
      ordered_resources = described_class.order_by_created_at_desc

      expect(ordered_resources.to_a).to eq([resource3, resource2, resource1])
    end
  end

  describe '.order_by_created_at_asc' do
    it 'returns catalog resources sorted by ascending created at' do
      ordered_resources = described_class.order_by_created_at_asc

      expect(ordered_resources.to_a).to eq([resource1, resource2, resource3])
    end
  end

  describe '.order_by_name_desc' do
    subject(:ordered_resources) { described_class.order_by_name_desc }

    it 'returns catalog resources sorted by descending name' do
      expect(ordered_resources.pluck(:name)).to eq(%w[Z L A])
    end

    it 'returns catalog resources sorted by descending name with nulls last' do
      resource1.update!(name: nil)

      expect(ordered_resources.pluck(:name)).to eq(['Z', 'L', nil])
    end
  end

  describe '.order_by_name_asc' do
    subject(:ordered_resources) { described_class.order_by_name_asc }

    it 'returns catalog resources sorted by ascending name' do
      expect(ordered_resources.pluck(:name)).to eq(%w[A L Z])
    end

    it 'returns catalog resources sorted by ascending name with nulls last' do
      resource1.update!(name: nil)

      expect(ordered_resources.pluck(:name)).to eq(['L', 'Z', nil])
    end
  end

  describe '.order_by_latest_released_at_desc' do
    it 'returns catalog resources sorted by latest_released_at descending with nulls last' do
      ordered_resources = described_class.order_by_latest_released_at_desc

      expect(ordered_resources).to eq([resource2, resource1, resource3])
    end
  end

  describe '.order_by_latest_released_at_asc' do
    it 'returns catalog resources sorted by latest_released_at ascending with nulls last' do
      ordered_resources = described_class.order_by_latest_released_at_asc

      expect(ordered_resources).to eq([resource1, resource2, resource3])
    end
  end

  describe '#state' do
    it 'defaults to draft' do
      expect(resource1.state).to eq('draft')
    end
  end

  describe '#publish!' do
    context 'when the catalog resource is in draft state' do
      it 'updates the state of the catalog resource to published' do
        expect(resource1.state).to eq('draft')

        resource1.publish!

        expect(resource1.reload.state).to eq('published')
      end
    end

    context 'when the catalog resource already has a published state' do
      it 'leaves the state as published' do
        resource1.update!(state: :published)
        expect(resource1.state).to eq('published')

        resource1.publish!

        expect(resource1.state).to eq('published')
      end
    end
  end

  describe '#unpublish!' do
    context 'when the catalog resource is in published state' do
      it 'updates the state of the catalog resource to draft' do
        resource1.update!(state: :published)
        expect(resource1.state).to eq('published')

        resource1.unpublish!

        expect(resource1.reload.state).to eq('draft')
      end
    end

    context 'when the catalog resource is already in draft state' do
      it 'leaves the state as draft' do
        expect(resource1.state).to eq('draft')

        resource1.unpublish!

        expect(resource1.reload.state).to eq('draft')
      end
    end
  end

  describe 'synchronizing denormalized columns with `projects` table' do
    shared_examples 'denormalized columns of the catalog resource match the project' do
      it do
        resource1.reload
        project1.reload

        expect(resource1.name).to eq(project1.name)
        expect(resource1.description).to eq(project1.description)
        expect(resource1.visibility_level).to eq(project1.visibility_level)
      end
    end

    context 'when the catalog resource is created' do
      it 'calls sync_with_project' do
        new_project = create(:project)
        new_resource = build(:ci_catalog_resource, project: new_project)

        expect(new_resource).to receive(:sync_with_project).once

        new_resource.save!
      end

      it_behaves_like 'denormalized columns of the catalog resource match the project'
    end

    context 'when the project attributes are updated' do
      before_all do
        project1.update!(
          name: 'New name',
          description: 'New description',
          visibility_level: Gitlab::VisibilityLevel::INTERNAL
        )
      end

      it_behaves_like 'denormalized columns of the catalog resource match the project'
    end
  end

  describe '#update_latest_released_at! triggered in model callbacks' do
    let_it_be(:project) { create(:project) }
    let_it_be(:resource) { create(:ci_catalog_resource, project: project) }

    let_it_be_with_refind(:january_release) do
      create(:release, :with_catalog_resource_version, project: project, tag: 'v1', released_at: '2023-01-01T00:00:00Z')
    end

    let_it_be_with_refind(:february_release) do
      create(:release, :with_catalog_resource_version, project: project, tag: 'v2', released_at: '2023-02-01T00:00:00Z')
    end

    it 'has the expected latest_released_at value' do
      expect(resource.reload.latest_released_at).to eq(february_release.released_at)
    end

    context 'when a new catalog resource version is created' do
      it 'updates the latest_released_at value' do
        march_release = create(:release, :with_catalog_resource_version, project: project, tag: 'v3',
          released_at: '2023-03-01T00:00:00Z')

        expect(resource.reload.latest_released_at).to eq(march_release.released_at)
      end
    end

    context 'when a catalog resource version is destroyed' do
      it 'updates the latest_released_at value' do
        february_release.catalog_resource_version.destroy!

        expect(resource.reload.latest_released_at).to eq(january_release.released_at)
      end
    end

    context 'when the released_at value of a release is updated' do
      it 'updates the latest_released_at value' do
        january_release.update!(released_at: '2024-01-01T00:00:00Z')

        expect(resource.reload.latest_released_at).to eq(january_release.released_at)
      end
    end

    context 'when a release is destroyed' do
      it 'updates the latest_released_at value' do
        february_release.destroy!
        expect(resource.reload.latest_released_at).to eq(january_release.released_at)
      end
    end

    context 'when all releases associated with the catalog resource are destroyed' do
      it 'updates the latest_released_at value to nil' do
        january_release.destroy!
        february_release.destroy!

        expect(resource.reload.latest_released_at).to be_nil
      end
    end
  end
end
