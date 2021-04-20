# frozen_string_literal: true

require 'spec_helper'

RSpec.describe EnvironmentSerializer do
  include CreateEnvironmentsHelpers

  let_it_be(:user) { create(:user) }
  let_it_be(:project, reload: true) { create(:project, :repository) }

  let(:json) do
    described_class
      .new(current_user: user, project: project)
      .represent(resource)
  end

  before_all do
    project.add_developer(user)
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
        create(:environment, name: 'staging')
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
        create(:environment, name: 'staging/my-review-1')
        create(:environment, name: 'staging/my-review-2')
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
        create(:environment, name: 'staging/my-review-1')
        create(:environment, name: 'staging/my-review-2')
        create(:environment, name: 'production/my-review-3')
        create(:environment, name: 'testing')
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
          create(:environment)
        end

        it 'serializes environments' do
          expect(subject.first).to have_key :id
        end
      end

      context 'when multiple environment objects are serialized' do
        before do
          create_list(:environment, 3)
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
          create(:environment, name: 'staging/review-1')
          create(:environment, name: 'staging/review-2')
          create(:environment, name: 'production/deploy-3')
          create(:environment, name: 'testing')
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

  def create_environment_with_associations(project)
    create(:environment, project: project).tap do |environment|
      create(:deployment, :success, environment: environment, project: project)
      create(:deployment, :running, environment: environment, project: project)
    end
  end
end
