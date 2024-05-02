# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentSerializer, feature_category: :continuous_delivery do
  include CreateEnvironmentsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :repository, developers: user) }

  let(:json) do
    described_class
      .new(current_user: user, project: project)
      .represent(resource)
  end

  it_behaves_like 'avoid N+1 on environments serialization'

  context 'when there is a collection of objects provided' do
    let(:resource) { project.environments }

    before_all do
      create_list(:environment, 2, project: project)
    end

    it 'contains important elements of environment' do
      expect(json.first)
        .to include(:last_deployment, :name, :external_url)
    end

    it 'generates payload for collection' do
      expect(json).to be_an_instance_of Array
    end
  end

  context 'when representing environments within folders' do
    let(:serializer) do
      described_class
        .new(current_user: user, project: project)
        .within_folders
    end

    let(:resource) { Environment.all }

    subject { serializer.represent(resource) }

    context 'when there is a single environment' do
      before do
        create(:environment, project: project, name: 'staging')
      end

      it 'represents one standalone environment' do
        expect(subject.count).to eq 1
        expect(subject.first[:name]).to eq 'staging'
        expect(subject.first[:size]).to eq 1
        expect(subject.first[:latest][:name]).to eq 'staging'
      end
    end

    context 'when there are multiple environments in folder' do
      before do
        create(:environment, project: project, name: 'staging/my-review-1')
        create(:environment, project: project, name: 'staging/my-review-2')
      end

      it 'represents one item that is a folder' do
        expect(subject.count).to eq 1
        expect(subject.first[:name]).to eq 'staging'
        expect(subject.first[:size]).to eq 2
        expect(subject.first[:latest][:name]).to eq 'staging/my-review-2'
        expect(subject.first[:latest][:environment_type]).to eq 'staging'
      end
    end

    context 'when there are multiple folders and standalone environments' do
      before do
        create(:environment, project: project, name: 'staging/my-review-1')
        create(:environment, project: project, name: 'staging/my-review-2')
        create(:environment, project: project, name: 'production/my-review-3')
        create(:environment, project: project, name: 'testing')
      end

      it 'represents multiple items grouped within folders' do
        expect(subject.count).to eq 3

        expect(subject.first[:name]).to eq 'production'
        expect(subject.first[:size]).to eq 1
        expect(subject.first[:latest][:name]).to eq 'production/my-review-3'
        expect(subject.first[:latest][:environment_type]).to eq 'production'
        expect(subject.second[:name]).to eq 'staging'
        expect(subject.second[:size]).to eq 2
        expect(subject.second[:latest][:name]).to eq 'staging/my-review-2'
        expect(subject.second[:latest][:environment_type]).to eq 'staging'
        expect(subject.third[:name]).to eq 'testing'
        expect(subject.third[:size]).to eq 1
        expect(subject.third[:latest][:name]).to eq 'testing'
        expect(subject.third[:latest][:environment_type]).to be_nil
      end
    end

    context 'when folders and standalone environments share the same name' do
      before do
        create(:environment, project: project, name: 'staging/my-review-1')
        create(:environment, project: project, name: 'staging/my-review-2')
        create(:environment, project: project, name: 'production/my-review-3')
        create(:environment, project: project, name: 'staging')
        create(:environment, project: project, name: 'testing')
      end

      it 'does not group standalone environments with folders that have the same name' do
        expect(subject.count).to eq 4

        expect(subject.first[:name]).to eq 'production'
        expect(subject.first[:size]).to eq 1
        expect(subject.first[:latest][:name]).to eq 'production/my-review-3'
        expect(subject.first[:latest][:environment_type]).to eq 'production'
        expect(subject.second[:name]).to eq 'staging'
        expect(subject.second[:size]).to eq 1
        expect(subject.second[:latest][:name]).to eq 'staging'
        expect(subject.second[:latest][:environment_type]).to be_nil
        expect(subject.third[:name]).to eq 'staging'
        expect(subject.third[:size]).to eq 2
        expect(subject.third[:latest][:name]).to eq 'staging/my-review-2'
        expect(subject.third[:latest][:environment_type]).to eq 'staging'
        expect(subject.fourth[:name]).to eq 'testing'
        expect(subject.fourth[:size]).to eq 1
        expect(subject.fourth[:latest][:name]).to eq 'testing'
        expect(subject.fourth[:latest][:environment_type]).to be_nil
      end
    end
  end

  context 'when used with pagination' do
    let(:request) { double(url: "#{Gitlab.config.gitlab.url}:8080/api/v4/projects?#{query.to_query}", query_parameters: query) }
    let(:response) { spy('response') }
    let(:resource) { Environment.all }
    let(:query) { { page: 1, per_page: 2 } }

    let(:serializer) do
      described_class
        .new(current_user: user, project: project)
        .with_pagination(request, response)
    end

    subject { serializer.represent(resource) }

    it 'creates a paginated serializer' do
      expect(serializer).to be_paginated
    end

    context 'when resource is paginatable relation' do
      context 'when there is a single environment object in relation' do
        before do
          create(:environment, project: project)
        end

        it 'serializes environments' do
          expect(subject.first).to have_key :id
        end
      end

      context 'when multiple environment objects are serialized' do
        before do
          create_list(:environment, 3, project: project)
        end

        it 'serializes appropriate number of objects' do
          expect(subject.count).to be 2
        end

        it 'appends relevant headers' do
          expect(response).to receive(:[]=).with('X-Total', '3')
          expect(response).to receive(:[]=).with('X-Total-Pages', '2')
          expect(response).to receive(:[]=).with('X-Per-Page', '2')

          subject
        end
      end

      context 'when grouping environments within folders' do
        let(:serializer) do
          described_class
            .new(current_user: user, project: project)
            .with_pagination(request, response)
            .within_folders
        end

        before do
          create(:environment, project: project, name: 'staging/review-1')
          create(:environment, project: project, name: 'staging/review-2')
          create(:environment, project: project, name: 'production/deploy-3')
          create(:environment, project: project, name: 'testing')
        end

        it 'paginates grouped items including ordering' do
          expect(subject.count).to eq 2
          expect(subject.first[:name]).to eq 'production'
          expect(subject.second[:name]).to eq 'staging'
        end

        it 'appends correct total page count header' do
          expect(subject).not_to be_empty
          expect(response).to have_received(:[]=).with('X-Total', '3')
        end

        it 'appends correct page count headers' do
          expect(subject).not_to be_empty
          expect(response).to have_received(:[]=).with('X-Total-Pages', '2')
          expect(response).to have_received(:[]=).with('X-Per-Page', '2')
        end
      end
    end
  end

  context 'batching loading' do
    let(:resource) { Environment.all }

    before do
      create(:environment, project: project, name: 'staging/review-1')
      create_environment_with_associations(project)
    end

    it 'uses the custom preloader service' do
      expect_next_instance_of(Preloaders::Environments::DeploymentPreloader) do |preloader|
        expect(preloader).to receive(:execute_with_union).with(:last_finished_deployment, hash_including(:deployable)).and_call_original
      end

      expect_next_instance_of(Preloaders::Environments::DeploymentPreloader) do |preloader|
        expect(preloader).to receive(:execute_with_union).with(:last_deployment, hash_including(:deployable)).and_call_original
      end

      expect_next_instance_of(Preloaders::Environments::DeploymentPreloader) do |preloader|
        expect(preloader).to receive(:execute_with_union).with(:upcoming_deployment, hash_including(:deployable)).and_call_original
      end

      json
    end

    # Validates possible bug that can arise when order_by is not honoured in the preloader.
    # See: https://gitlab.com/gitlab-org/gitlab/-/issues/353966#note_861381504
    it 'fetches the last and upcoming deployment correctly' do
      last_deployment = nil
      upcoming_deployment = nil
      create(:environment, project: project).tap do |environment|
        create(:deployment, :success, environment: environment, project: project)

        create(:ci_build, :success, project: project).tap do |build|
          last_deployment = create(:deployment, :success, environment: environment, project: project, deployable: build)
        end

        create(:deployment, :running, environment: environment, project: project)
        upcoming_deployment = create(:deployment, :running, environment: environment, project: project)
      end

      response_json = json

      expect(response_json.last[:last_deployment][:id]).to eq(last_deployment.id)
      expect(response_json.last[:upcoming_deployment][:id]).to eq(upcoming_deployment.id)
    end

    describe 'batch loading environment deployment groups' do
      let(:environments) { Environment.all.to_a }

      before do
        environments.each do |env|
          allow(env).to receive(:last_finished_deployment_group).and_call_original
        end

        allow(resource).to receive(:to_a).and_return(environments)
      end

      it "batch loads each environment's last_finished_deployment_group" do
        expect(environments).to all(receive(:last_finished_deployment_group))

        json
      end
    end
  end

  def create_environment_with_associations(project)
    create(:environment, project: project).tap do |environment|
      create(:ci_pipeline, project: project).tap do |pipeline|
        create(
          :ci_build, :manual, project: project, pipeline: pipeline, name: 'stop-action', environment: environment.name
        )

        create(:ci_build, :scheduled, project: project, pipeline: pipeline,
          environment: environment.name).tap do |scheduled_build|
            create(:deployment, :running, environment: environment, project: project,
              deployable: scheduled_build)
          end

        create(:ci_build, :success, :manual, project: project, pipeline: pipeline,
          environment: environment.name).tap do |manual_build|
            create(:deployment, :success, environment: environment, project: project,
              deployable: manual_build, on_stop: 'stop-action')
          end
      end
    end
  end
end
