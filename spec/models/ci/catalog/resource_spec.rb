# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  it { is_expected.to belong_to(:project) }

  it { is_expected.to delegate_method(:avatar_path).to(:project) }
  it { is_expected.to delegate_method(:description).to(:project) }
  it { is_expected.to delegate_method(:name).to(:project) }

  describe '.for_projects' do
    it 'returns catalog resources for the given project IDs' do
      project = create(:project)
      resource = create(:catalog_resource, project: project)

      resources_for_projects = described_class.for_projects(project.id)

      expect(resources_for_projects).to contain_exactly(resource)
    end
  end
end
