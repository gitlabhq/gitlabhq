# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::ValidateResourceService, feature_category: :pipeline_composition do
  describe '#execute' do
    context 'with a project that has a README and a description' do
      it 'is valid' do
        project = create(:project, :repository, description: 'Component project')
        response = described_class.new(project, project.default_branch).execute

        expect(response).to be_success
      end
    end

    context 'with a project that has neither a description nor a README' do
      it 'is not valid' do
        project = create(:project, :empty_repo)
        project.repository.create_file(
          project.creator,
          'ruby.rb',
          'I like this',
          message: 'Ruby like this',
          branch_name: 'master'
        )
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq('Project must have a README , Project must have a description')
      end
    end

    context 'with a project that has a description but not a README' do
      it 'is not valid' do
        project = create(:project, :empty_repo, description: 'project with no README')
        project.repository.create_file(
          project.creator,
          'text.txt',
          'I do not like this',
          message: 'only text like text',
          branch_name: 'master'
        )
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq('Project must have a README')
      end
    end

    context 'with a project that has a README and not a description' do
      it 'is not valid' do
        project = create(:project, :repository)
        response = described_class.new(project, project.default_branch).execute

        expect(response.message).to eq('Project must have a description')
      end
    end
  end
end
