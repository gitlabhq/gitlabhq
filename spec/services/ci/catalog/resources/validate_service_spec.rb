# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::ValidateService, feature_category: :pipeline_composition do
  describe '#execute' do
    context 'when a project has a README, a description, and at least one component' do
      it 'is valid' do
        project = create(:project, :catalog_resource_with_components)
        response = described_class.new(project, project.default_branch).execute

        expect(response).to be_success
      end
    end

    context 'when a project has neither a description nor a README nor components' do
      it 'is not valid' do
        project = create(:project, :small_repo)
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq(
          'Project must have a README, ' \
          'Project must have a description, ' \
          'Project must contain components. Ensure you are using the correct directory structure')
      end
    end

    context 'when a project has components but has neither a description nor a README' do
      it 'is not valid' do
        project = create(:project, :small_repo, files: { 'templates/dast/template.yml' => 'image: alpine' })
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq('Project must have a README, Project must have a description')
      end
    end

    context 'when a project has a description but has neither a README nor components' do
      it 'is not valid' do
        project = create(:project, :small_repo, description: 'project with no README and no components')
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq(
          'Project must have a README, ' \
          'Project must contain components. Ensure you are using the correct directory structure')
      end
    end

    context 'when a project has a README but has neither a description nor components' do
      it 'is not valid' do
        project = create(:project, :repository)
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq(
          'Project must have a description, ' \
          'Project must contain components. Ensure you are using the correct directory structure')
      end
    end

    context 'when a project has components and a description but no README' do
      it 'is not valid' do
        project = create(:project, :small_repo, description: 'desc', files: { 'templates/dast.yml' => 'image: alpine' })
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq('Project must have a README')
      end
    end

    context 'when a project has components and a README but no description' do
      it 'is not valid' do
        project = create(:project, :custom_repo,
          files: { 'templates/dast.yml' => 'image: alpine', 'README.md' => 'readme' })
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq('Project must have a description')
      end
    end

    context 'when a project has a description and a README but no components' do
      it 'is not valid' do
        project = create(:project, :readme, description: 'project with no README and no components')
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq(
          'Project must contain components. Ensure you are using the correct directory structure')
      end
    end
  end
end
