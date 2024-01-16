# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CloudSeed::GoogleCloud::GeneratePipelineService, feature_category: :deployment_management do
  describe 'for cloud-run' do
    describe 'when there is no existing pipeline' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:service_params) { { action: described_class::ACTION_DEPLOY_TO_CLOUD_RUN } }
      let_it_be(:service) { described_class.new(project, maintainer, service_params) }

      before do
        project.add_maintainer(maintainer)
      end

      it 'creates a new branch with commit for cloud-run deployment' do
        response = service.execute

        branch_name = response[:branch_name]
        commit = response[:commit]
        local_branches = project.repository.local_branches
        created_branch = local_branches.find { |branch| branch.name == branch_name }

        expect(response[:status]).to eq(:success)
        expect(branch_name).to start_with('deploy-to-cloud-run-')
        expect(created_branch).to be_present
        expect(created_branch.target).to eq(commit[:result])
      end

      it 'generated pipeline includes cloud-run deployment' do
        response = service.execute

        ref = response[:commit][:result]
        gitlab_ci_yml = project.ci_config_for(ref)

        expect(response[:status]).to eq(:success)
        expect(gitlab_ci_yml).to include('https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/gcp/cloud-run.gitlab-ci.yml')
      end

      context 'simulate errors' do
        it 'fails to create branch' do
          allow_next_instance_of(Branches::CreateService) do |create_service|
            allow(create_service).to receive(:execute)
                                       .and_return({ status: :error })
          end

          response = service.execute
          expect(response[:status]).to eq(:error)
        end

        it 'fails to commit changes' do
          allow_next_instance_of(Files::CreateService) do |create_service|
            allow(create_service).to receive(:execute)
                                       .and_return({ status: :error })
          end

          response = service.execute
          expect(response[:status]).to eq(:error)
        end
      end
    end

    describe 'when there is an existing pipeline without `deploy` stage' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:service_params) do
        { action: CloudSeed::GoogleCloud::GeneratePipelineService::ACTION_DEPLOY_TO_CLOUD_RUN }
      end

      let_it_be(:service) { described_class.new(project, maintainer, service_params) }

      before_all do
        project.add_maintainer(maintainer)

        file_name = '.gitlab-ci.yml'
        file_content = <<EOF
stages:
  - build
  - test

build-java:
  stage: build
  script: mvn clean install

test-java:
  stage: test
  script: mvn clean test
EOF
        project.repository.create_file(
          maintainer,
          file_name,
          file_content,
          message: 'Pipeline with three stages and two jobs',
          branch_name: project.default_branch
        )
      end

      it 'introduces a `deploy` stage and includes the deploy-to-cloud-run job' do
        response = service.execute

        branch_name = response[:branch_name]
        gitlab_ci_yml = project.ci_config_for(branch_name)
        pipeline = Gitlab::Config::Loader::Yaml.new(gitlab_ci_yml).load!

        expect(response[:status]).to eq(:success)
        expect(pipeline[:stages]).to eq(%w[build test deploy])
        expect(pipeline[:include]).to be_present
        expect(gitlab_ci_yml).to include('https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/gcp/cloud-run.gitlab-ci.yml')
      end

      it 'stringifies keys from the existing pipelines' do
        response = service.execute

        branch_name = response[:branch_name]
        gitlab_ci_yml = project.ci_config_for(branch_name)

        expect(YAML.safe_load(gitlab_ci_yml).keys).to eq(%w[stages build-java test-java include])
      end
    end

    describe 'when there is an existing pipeline with `deploy` stage' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:service_params) do
        { action: CloudSeed::GoogleCloud::GeneratePipelineService::ACTION_DEPLOY_TO_CLOUD_RUN }
      end

      let_it_be(:service) { described_class.new(project, maintainer, service_params) }

      before do
        project.add_maintainer(maintainer)

        file_name = '.gitlab-ci.yml'
        file_content = <<EOF
stages:
  - build
  - test
  - deploy

build-java:
  stage: build
  script: mvn clean install

test-java:
  stage: test
  script: mvn clean test
EOF
        project.repository.create_file(
          maintainer,
          file_name,
          file_content,
          message: 'Pipeline with three stages and two jobs',
          branch_name: project.default_branch
        )
      end

      it 'includes the deploy-to-cloud-run job' do
        response = service.execute

        branch_name = response[:branch_name]
        gitlab_ci_yml = project.ci_config_for(branch_name)
        pipeline = Gitlab::Config::Loader::Yaml.new(gitlab_ci_yml).load!

        expect(response[:status]).to eq(:success)
        expect(pipeline[:stages]).to eq(%w[build test deploy])
        expect(pipeline[:include]).to be_present
        expect(gitlab_ci_yml).to include('https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/gcp/cloud-run.gitlab-ci.yml')
      end
    end

    describe 'when there is an existing pipeline with `includes`' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:service_params) do
        { action: CloudSeed::GoogleCloud::GeneratePipelineService::ACTION_DEPLOY_TO_CLOUD_RUN }
      end

      let_it_be(:service) { described_class.new(project, maintainer, service_params) }

      before do
        project.add_maintainer(maintainer)

        file_name = '.gitlab-ci.yml'
        file_content = <<EOF
stages:
  - build
  - test
  - deploy

include:
  local: 'some-pipeline.yml'
EOF
        project.repository.create_file(
          maintainer,
          file_name,
          file_content,
          message: 'Pipeline with three stages and two jobs',
          branch_name: project.default_branch
        )
      end

      it 'includes the deploy-to-cloud-run job' do
        response = service.execute

        branch_name = response[:branch_name]
        gitlab_ci_yml = project.ci_config_for(branch_name)
        pipeline = Gitlab::Config::Loader::Yaml.new(gitlab_ci_yml).load!

        expect(response[:status]).to eq(:success)
        expect(pipeline[:stages]).to eq(%w[build test deploy])
        expect(pipeline[:include]).to be_present
        expect(gitlab_ci_yml).to include('https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/gcp/cloud-run.gitlab-ci.yml')
      end
    end
  end

  describe 'for cloud-storage' do
    describe 'when there is no existing pipeline' do
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:maintainer) { create(:user) }
      let_it_be(:service_params) do
        { action: CloudSeed::GoogleCloud::GeneratePipelineService::ACTION_DEPLOY_TO_CLOUD_STORAGE }
      end

      let_it_be(:service) { described_class.new(project, maintainer, service_params) }

      before do
        project.add_maintainer(maintainer)
      end

      it 'creates a new branch with commit for cloud-storage deployment' do
        response = service.execute

        branch_name = response[:branch_name]
        commit = response[:commit]
        local_branches = project.repository.local_branches
        search_for_created_branch = local_branches.find { |branch| branch.name == branch_name }

        expect(response[:status]).to eq(:success)
        expect(branch_name).to start_with('deploy-to-cloud-storage-')
        expect(search_for_created_branch).to be_present
        expect(search_for_created_branch.target).to eq(commit[:result])
      end

      it 'generated pipeline includes cloud-storage deployment' do
        response = service.execute

        ref = response[:commit][:result]
        gitlab_ci_yml = project.ci_config_for(ref)

        expect(response[:status]).to eq(:success)
        expect(gitlab_ci_yml).to include('https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/gcp/cloud-storage.gitlab-ci.yml')
      end
    end
  end

  describe 'for vision ai' do
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:maintainer) { create(:user) }
    let_it_be(:service_params) { { action: described_class::ACTION_VISION_AI_PIPELINE } }
    let_it_be(:service) { described_class.new(project, maintainer, service_params) }

    describe 'when there is no existing pipeline' do
      before do
        project.add_maintainer(maintainer)
      end

      it 'creates a new branch with commit for cloud-run deployment' do
        response = service.execute

        branch_name = response[:branch_name]
        commit = response[:commit]
        local_branches = project.repository.local_branches
        created_branch = local_branches.find { |branch| branch.name == branch_name }

        expect(response[:status]).to eq(:success)
        expect(branch_name).to start_with('vision-ai-pipeline-')
        expect(created_branch).to be_present
        expect(created_branch.target).to eq(commit[:result])
      end

      it 'generated pipeline includes vision ai deployment' do
        response = service.execute

        ref = response[:commit][:result]
        gitlab_ci_yml = project.ci_config_for(ref)

        expect(response[:status]).to eq(:success)
        expect(gitlab_ci_yml).to include('https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/gcp/vision-ai.gitlab-ci.yml')
      end

      context 'simulate errors' do
        it 'fails to create branch' do
          allow_next_instance_of(Branches::CreateService) do |create_service|
            allow(create_service).to receive(:execute)
                                       .and_return({ status: :error })
          end

          response = service.execute
          expect(response[:status]).to eq(:error)
        end

        it 'fails to commit changes' do
          allow_next_instance_of(Files::CreateService) do |create_service|
            allow(create_service).to receive(:execute)
                                       .and_return({ status: :error })
          end

          response = service.execute
          expect(response[:status]).to eq(:error)
        end
      end
    end

    describe 'when there is an existing pipeline with `includes`' do
      before do
        project.add_maintainer(maintainer)

        file_name = '.gitlab-ci.yml'
        file_content = <<EOF
stages:
  - validate
  - detect
  - render

include:
  local: 'some-pipeline.yml'
EOF
        project.repository.create_file(
          maintainer,
          file_name,
          file_content,
          message: 'Pipeline with three stages and two jobs',
          branch_name: project.default_branch
        )
      end

      it 'includes the vision ai pipeline' do
        response = service.execute

        branch_name = response[:branch_name]
        gitlab_ci_yml = project.ci_config_for(branch_name)
        pipeline = Gitlab::Config::Loader::Yaml.new(gitlab_ci_yml).load!

        expect(response[:status]).to eq(:success)
        expect(pipeline[:stages]).to eq(%w[validate detect render])
        expect(pipeline[:include]).to be_present
        expect(gitlab_ci_yml).to include('https://gitlab.com/gitlab-org/incubation-engineering/five-minute-production/library/-/raw/main/gcp/vision-ai.gitlab-ci.yml')
      end
    end
  end
end
