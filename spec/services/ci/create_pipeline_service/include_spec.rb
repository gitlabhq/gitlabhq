# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::CreatePipelineService,
  :yaml_processor_feature_flag_corectness, feature_category: :pipeline_composition do
  include RepoHelpers

  context 'include:' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:user)    { project.first_owner }

    let(:ref)                  { 'refs/heads/master' }
    let(:variables_attributes) { [{ key: 'MYVAR', secret_value: 'hello' }] }
    let(:source)               { :push }

    let(:service)  { described_class.new(project, user, { ref: ref, variables_attributes: variables_attributes }) }
    let(:pipeline) { service.execute(source).payload }

    let(:file_location) { 'spec/fixtures/gitlab/ci/external_files/.gitlab-ci-template-1.yml' }

    let(:project_files) do
      {
        '.gitlab-ci.yml' => config,
        file_location => File.read(Rails.root.join(file_location))
      }
    end

    around do |example|
      create_and_delete_files(project, project_files) do
        example.run
      end
    end

    shared_examples 'not including the file' do
      it 'does not include the job in the file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.processables.pluck(:name)).to contain_exactly('job')
      end
    end

    shared_examples 'including the file' do
      it 'includes the job in the file' do
        expect(pipeline).to be_created_successfully
        expect(pipeline.processables.pluck(:name)).to contain_exactly('job', 'rspec')
      end
    end

    context 'with a local file' do
      let(:config) do
        <<~EOY
        include: #{file_location}
        job:
          script: exit 0
        EOY
      end

      it_behaves_like 'including the file'
    end

    context 'with a local file with rules with a project variable' do
      let(:config) do
        <<~EOY
        include:
          - local: #{file_location}
            rules:
              - if: $CI_PROJECT_ID == "#{project_id}"
        job:
          script: exit 0
        EOY
      end

      context 'when the rules matches' do
        let(:project_id) { project.id }

        it_behaves_like 'including the file'
      end

      context 'when the rules does not match' do
        let(:project_id) { non_existing_record_id }

        it_behaves_like 'not including the file'
      end
    end

    context 'with a local file with rules with a predefined pipeline variable' do
      let(:config) do
        <<~EOY
        include:
          - local: #{file_location}
            rules:
              - if: $CI_PIPELINE_SOURCE == "#{pipeline_source}"
        job:
          script: exit 0
        EOY
      end

      context 'when the rules matches' do
        let(:pipeline_source) { 'push' }

        it_behaves_like 'including the file'
      end

      context 'when the rules does not match' do
        let(:pipeline_source) { 'web' }

        it_behaves_like 'not including the file'
      end
    end

    context 'with a local file with rules with a run pipeline variable' do
      let(:config) do
        <<~EOY
        include:
          - local: #{file_location}
            rules:
              - if: $MYVAR == "#{my_var}"
        job:
          script: exit 0
        EOY
      end

      context 'when the rules matches' do
        let(:my_var) { 'hello' }

        it_behaves_like 'including the file'
      end

      context 'when the rules does not match' do
        let(:my_var) { 'mello' }

        it_behaves_like 'not including the file'
      end
    end
  end
end
