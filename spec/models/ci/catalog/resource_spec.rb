# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  let_it_be(:today) { Time.zone.now }
  let_it_be(:yesterday) { today - 1.day }
  let_it_be(:tomorrow) { today + 1.day }

  let_it_be_with_reload(:project) { create(:project, name: 'A') }
  let_it_be(:project_2) { build(:project, name: 'Z') }
  let_it_be(:project_3) { build(:project, name: 'L', description: 'Z') }
  let_it_be_with_reload(:resource) { create(:ci_catalog_resource, project: project, latest_released_at: tomorrow) }
  let_it_be(:resource_2) { create(:ci_catalog_resource, project: project_2, latest_released_at: today) }
  let_it_be(:resource_3) { create(:ci_catalog_resource, project: project_3, latest_released_at: nil) }

  let_it_be(:release1) { create(:release, project: project, released_at: yesterday) }
  let_it_be(:release2) { create(:release, project: project, released_at: today) }
  let_it_be(:release3) { create(:release, project: project, released_at: tomorrow) }

  it { is_expected.to belong_to(:project) }

  it do
    is_expected.to(
      have_many(:components).class_name('Ci::Catalog::Resources::Component').with_foreign_key(:catalog_resource_id)
    )
  end

  it { is_expected.to have_many(:versions).class_name('Ci::Catalog::Resources::Version') }

  it { is_expected.to delegate_method(:avatar_path).to(:project) }
  it { is_expected.to delegate_method(:star_count).to(:project) }
  it { is_expected.to delegate_method(:forks_count).to(:project) }

  it { is_expected.to define_enum_for(:state).with_values({ draft: 0, published: 1 }) }

  describe '.for_projects' do
    it 'returns catalog resources for the given project IDs' do
      resources_for_projects = described_class.for_projects(project.id)

      expect(resources_for_projects).to contain_exactly(resource)
    end
  end

  describe '.search' do
    it 'returns catalog resources whose name or description match the search term' do
      resources = described_class.search('Z')

      expect(resources).to contain_exactly(resource_2, resource_3)
    end
  end

  describe '.order_by_created_at_desc' do
    it 'returns catalog resources sorted by descending created at' do
      ordered_resources = described_class.order_by_created_at_desc

      expect(ordered_resources.to_a).to eq([resource_3, resource_2, resource])
    end
  end

  describe '.order_by_created_at_asc' do
    it 'returns catalog resources sorted by ascending created at' do
      ordered_resources = described_class.order_by_created_at_asc

      expect(ordered_resources.to_a).to eq([resource, resource_2, resource_3])
    end
  end

  describe '.order_by_name_desc' do
    subject(:ordered_resources) { described_class.order_by_name_desc }

    it 'returns catalog resources sorted by descending name' do
      expect(ordered_resources.pluck(:name)).to eq(%w[Z L A])
    end

    it 'returns catalog resources sorted by descending name with nulls last' do
      resource.update!(name: nil)

      expect(ordered_resources.pluck(:name)).to eq(['Z', 'L', nil])
    end
  end

  describe '.order_by_name_asc' do
    subject(:ordered_resources) { described_class.order_by_name_asc }

    it 'returns catalog resources sorted by ascending name' do
      expect(ordered_resources.pluck(:name)).to eq(%w[A L Z])
    end

    it 'returns catalog resources sorted by ascending name with nulls last' do
      resource.update!(name: nil)

      expect(ordered_resources.pluck(:name)).to eq(['L', 'Z', nil])
    end
  end

  describe '.order_by_latest_released_at_desc' do
    it 'returns catalog resources sorted by latest_released_at descending with nulls last' do
      ordered_resources = described_class.order_by_latest_released_at_desc

      expect(ordered_resources).to eq([resource, resource_2, resource_3])
    end
  end

  describe '.order_by_latest_released_at_asc' do
    it 'returns catalog resources sorted by latest_released_at ascending with nulls last' do
      ordered_resources = described_class.order_by_latest_released_at_asc

      expect(ordered_resources).to eq([resource_2, resource, resource_3])
    end
  end

  describe '#versions' do
    it 'returns releases ordered by released date descending' do
      expect(resource.versions).to eq([release3, release2, release1])
    end
  end

  describe '#latest_version' do
    it 'returns the latest release' do
      expect(resource.latest_version).to eq(release3)
    end
  end

  describe '#state' do
    it 'defaults to draft' do
      expect(resource.state).to eq('draft')
    end
  end

  describe '#publish!' do
    context 'when the catalog resource is in draft state' do
      it 'updates the state of the catalog resource to published' do
        expect(resource.state).to eq('draft')

        resource.publish!

        expect(resource.reload.state).to eq('published')
      end
    end

    context 'when a catalog resource already has a published state' do
      it 'leaves the state as published' do
        resource.update!(state: 'published')

        resource.publish!

        expect(resource.state).to eq('published')
      end
    end
  end

  describe '#unpublish!' do
    context 'when the catalog resource is in published state' do
      it 'updates the state to draft' do
        resource.update!(state: :published)
        expect(resource.state).to eq('published')

        resource.unpublish!

        expect(resource.reload.state).to eq('draft')
      end
    end

    context 'when the catalog resource is already in draft state' do
      it 'leaves the state as draft' do
        expect(resource.state).to eq('draft')

        resource.unpublish!

        expect(resource.reload.state).to eq('draft')
      end
    end
  end

  describe 'sync with project' do
    shared_examples 'name and description of the catalog resource matches the project' do
      it do
        expect(resource.reload.name).to eq(project.name)
        expect(resource.reload.description).to eq(project.description)
      end
    end

    context 'when the catalog resource is created' do
      it_behaves_like 'name and description of the catalog resource matches the project'
    end

    context 'when the project name is updated' do
      before do
        project.update!(name: 'My new project name')
      end

      it_behaves_like 'name and description of the catalog resource matches the project'
    end

    context 'when the project description is updated' do
      before do
        project.update!(description: 'My new description')
      end

      it_behaves_like 'name and description of the catalog resource matches the project'
    end
  end
end
