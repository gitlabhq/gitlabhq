# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resource, feature_category: :pipeline_composition do
  describe '.for_projects' do
    it 'returns catalog resources for the given project IDs' do
      project = create(:project)
      resource = create(:catalog_resource, project: project)

      resources_for_projects = described_class.for_projects(project.id)

      expect(resources_for_projects).to contain_exactly(resource)
    end
  end
end
