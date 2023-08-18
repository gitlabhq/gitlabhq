# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project, name: 'A') }
  let_it_be(:project_2) { build(:project, name: 'Z') }
  let_it_be(:project_3) { build(:project, name: 'L') }
  let_it_be(:resource) { create(:catalog_resource, project: project) }
  let_it_be(:resource_2) { create(:catalog_resource, project: project_2) }
  let_it_be(:resource_3) { create(:catalog_resource, project: project_3) }

  let_it_be(:release1) { create(:release, project: project, released_at: Time.zone.now - 2.days) }
  let_it_be(:release2) { create(:release, project: project, released_at: Time.zone.now - 1.day) }
  let_it_be(:release3) { create(:release, project: project, released_at: Time.zone.now) }

  it { is_expected.to belong_to(:project) }
  it { is_expected.to have_many(:components).class_name('Ci::Catalog::Resources::Component') }
  it { is_expected.to have_many(:versions).class_name('Ci::Catalog::Resources::Version') }

  it { is_expected.to delegate_method(:avatar_path).to(:project) }
  it { is_expected.to delegate_method(:description).to(:project) }
  it { is_expected.to delegate_method(:name).to(:project) }
  it { is_expected.to delegate_method(:star_count).to(:project) }
  it { is_expected.to delegate_method(:forks_count).to(:project) }

  it { is_expected.to define_enum_for(:state).with_values({ draft: 0, published: 1 }) }

  describe '.for_projects' do
    it 'returns catalog resources for the given project IDs' do
      resources_for_projects = described_class.for_projects(project.id)

      expect(resources_for_projects).to contain_exactly(resource)
    end
  end

  describe '.order_by_created_at_desc' do
    it 'returns catalog resources sorted by descending created at' do
      ordered_resources = described_class.order_by_created_at_desc

      expect(ordered_resources.to_a).to eq([resource_3, resource_2, resource])
    end
  end

  describe '.order_by_name_desc' do
    it 'returns catalog resources sorted by descending name' do
      ordered_resources = described_class.order_by_name_desc

      expect(ordered_resources.pluck(:name)).to eq(%w[Z L A])
    end
  end

  describe '.order_by_name_asc' do
    it 'returns catalog resources sorted by ascending name' do
      ordered_resources = described_class.order_by_name_asc

      expect(ordered_resources.pluck(:name)).to eq(%w[A L Z])
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
end
