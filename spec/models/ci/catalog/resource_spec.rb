# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  let_it_be(:project) { create(:project) }
  let_it_be(:resource) { create(:catalog_resource, project: project) }

  let_it_be(:releases) do
    [
      create(:release, project: project, released_at: Time.zone.now - 2.days),
      create(:release, project: project, released_at: Time.zone.now - 1.day),
      create(:release, project: project, released_at: Time.zone.now)
    ]
  end

  it { is_expected.to belong_to(:project) }

  it { is_expected.to delegate_method(:avatar_path).to(:project) }
  it { is_expected.to delegate_method(:description).to(:project) }
  it { is_expected.to delegate_method(:name).to(:project) }

  describe '.for_projects' do
    it 'returns catalog resources for the given project IDs' do
      resources_for_projects = described_class.for_projects(project.id)

      expect(resources_for_projects).to contain_exactly(resource)
    end
  end

  describe '#versions' do
    it 'returns releases ordered by released date descending' do
      expect(resource.versions).to eq(releases.reverse)
    end
  end

  describe '#latest_version' do
    it 'returns the latest release' do
      expect(resource.latest_version).to eq(releases.last)
    end
  end
end
