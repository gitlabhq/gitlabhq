require 'spec_helper'

describe EnvironmentSerializer do
  let(:user) { create(:user) }
  let(:project) { create(:project) }

  let(:json) do
    described_class
      .new(user: user, project: project)
      .represent(resource)
  end

  context 'when there is a single object provided' do
    before do
      create(:ci_build, :manual, name: 'manual1',
                                 pipeline: deployable.pipeline)
    end

    let(:deployment) do
      create(:deployment, deployable: deployable,
                          user: user,
                          project: project,
                          sha: project.commit.id)
    end

    let(:deployable) { create(:ci_build) }
    let(:resource) { deployment.environment }

    it 'contains important elements of environment' do
      expect(json)
        .to include(:name, :external_url, :environment_path, :last_deployment)
    end

    it 'contains relevant information about last deployment' do
      last_deployment = json.fetch(:last_deployment)

      expect(last_deployment)
        .to include(:ref, :user, :commit, :deployable, :manual_actions)
    end
  end

  context 'when there is a collection of objects provided' do
    let(:project) { create(:empty_project) }
    let(:resource) { create_list(:environment, 2) }

    it 'contains important elements of environment' do
      expect(json.first)
        .to include(:last_deployment, :name, :external_url)
    end

    it 'generates payload for collection' do
      expect(json).to be_an_instance_of Array
    end
  end

  context 'when used with pagination' do
    let(:request) { spy('request') }
    let(:response) { spy('response') }
    let(:resource) { Environment.all }
    let(:pagination) { { page: 1, per_page: 2 } }

    let(:serializer) do
      described_class.new(project: project)
        .with_pagination(request, response)
    end

    before do
      allow(request).to receive(:query_parameters)
        .and_return(pagination)
    end

    subject { serializer.represent(resource) }

    it 'creates a paginated serializer' do
      expect(serializer).to be_paginated
    end

    context 'when resource is paginatable relation' do
      context 'when there is a single environment object in relation' do
        before { create(:environment) }

        it 'serializes environments' do
          expect(subject.first).to have_key :id
        end
      end

      context 'when multiple environment objects are serialized' do
        before { create_list(:environment, 3) }

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
    end
  end
end
