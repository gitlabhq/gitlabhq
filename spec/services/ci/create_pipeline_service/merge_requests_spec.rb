# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService,
  feature_category: :continuous_integration do
  context 'merge requests handling' do
    let_it_be(:project)  { create(:project, :repository) }
    let_it_be(:user)     { project.first_owner }

    let(:ref)      { 'refs/heads/feature' }
    let(:source)   { :push }
    let(:service)  { described_class.new(project, user, { ref: ref }) }
    let(:pipeline) { service.execute(source).payload }

    before do
      stub_ci_pipeline_yaml_file <<-EOS
        workflow:
          rules:
            # do not create pipelines if merge requests are opened
            - if: $CI_OPEN_MERGE_REQUESTS
              when: never

            - if: $CI_COMMIT_BRANCH

        rspec:
          script: echo Hello World
      EOS
    end

    context 'when pushing a change' do
      context 'when a merge request already exists' do
        let!(:merge_request) do
          create(
            :merge_request,
            source_project: project,
            source_branch: 'feature',
            target_project: project,
            target_branch: 'master'
          )
        end

        it 'does not create a pipeline' do
          expect(pipeline).not_to be_persisted
        end
      end

      context 'when no merge request exists' do
        it 'does create a pipeline' do
          expect(pipeline.errors).to be_empty
          expect(pipeline).to be_persisted
        end
      end
    end
  end
end
