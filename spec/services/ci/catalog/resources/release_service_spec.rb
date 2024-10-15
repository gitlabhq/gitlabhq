# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::ReleaseService, feature_category: :pipeline_composition do
  describe '#execute' do
    let(:metadata) { nil }
    let(:project) { create(:project, :catalog_resource_with_components) }
    let(:release) do
      create(:release, project: project, sha: project.repository.root_ref_sha, author: project.first_owner)
    end

    let(:user) { project.first_owner }

    subject(:execute) { described_class.new(release, user, metadata).execute }

    context 'when executing release service' do
      let(:histogram) { instance_double(Prometheus::Client::Histogram) }

      before do
        allow(Gitlab::Metrics).to receive(:histogram).and_call_original

        allow(::Gitlab::Metrics).to receive(:histogram).with(
          :gitlab_ci_catalog_release_duration_seconds,
          'CI Catalog Release duration',
          {},
          [0.01, 0.05, 0.1, 0.5, 1.0, 2.0, 5.0, 10.0, 20.0, 50.0, 240.0]
        ).and_return(histogram)
        allow(::Gitlab::Metrics::System).to receive(:monotonic_time).and_call_original
      end

      it 'tracks release duration' do
        expect(histogram).to receive(:observe).with({}, an_instance_of(Float))

        execute
      end
    end

    context 'with a valid catalog resource and release from passed data' do
      let!(:catalog_resource) { create(:ci_catalog_resource, project: project) }

      let(:metadata) do
        {
          components: [
            { name: 'hello-component', spec: { inputs: { hello: nil } }, component_type: 'template' }
          ]
        }
      end

      it 'validates the catalog resource and creates a version' do
        response = execute

        version = Ci::Catalog::Resources::Version.last

        expect(response).to be_success
        expect(response.payload[:version]).to eq(version)
        expect(version.release).to eq(release)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
        expect(version.components.count).to eq(1)
        expect(version.components.first.name).to eq('hello-component')
        expect(version.components.first.spec).to eq({ 'inputs' => { 'hello' => nil } })
      end

      context 'when the user does not have permission to publish a version' do
        let(:user) { create(:user) }

        before do
          project.add_reporter(user)
        end

        it 'returns an error' do
          response = execute

          expect(response).to be_error
          expect(response.message).to include('You are not authorized to publish a version to the CI/CD catalog')
        end
      end
    end

    context 'with a valid catalog resource and release from fetched data (LEGACY)' do
      let!(:catalog_resource) { create(:ci_catalog_resource, project: project) }

      it 'validates the catalog resource and creates a version' do
        response = execute

        version = Ci::Catalog::Resources::Version.last

        expect(response).to be_success
        expect(response.payload[:version]).to eq(version)
        expect(version.release).to eq(release)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
      end

      context 'when the user is not the author of the release' do
        let(:user) { create(:user) }

        before do
          project.add_maintainer(user)
        end

        it 'returns an error and does not create a version' do
          response = execute

          expect(Ci::Catalog::Resources::Version.count).to be(0)
          expect(response).to be_error
          expect(response.message).to include('Published by must be the same as the release author')
        end
      end
    end

    context 'when the validation of the catalog resource fails' do
      let(:project) { create(:project, :small_repo) }

      it 'returns an error and does not create a version' do
        create(:ci_catalog_resource, project: project)

        response = execute

        expect(Ci::Catalog::Resources::Version.count).to be(0)
        expect(response).to be_error
        expect(response.message).to include('Project must have a description')
        expect(response.message).to include(
          'Project must contain components. Ensure you are using the correct directory structure')
      end
    end

    context 'when the creation of a version fails from passed data' do
      let(:project) { create(:project, :catalog_resource_with_components) }
      let!(:catalog_resource) { create(:ci_catalog_resource, project: project) }

      let(:metadata) do
        {
          components: [
            { invalid: 'data' }
          ]
        }
      end

      it 'returns an error and does not create a version' do
        response = execute

        expect(Ci::Catalog::Resources::Version.count).to be(0)
        expect(response).to be_error
        expect(response.message).to include('Spec must be a valid json schema, Name can\'t be blank')
      end
    end

    context 'when the creation of a version fails from fetched data (LEGACY)' do
      let(:project) do
        create(
          :project, :custom_repo,
          description: 'Component project',
          files: {
            'templates/secret-detection.yml' => 'image: agent: coop',
            'README.md' => 'Read me'
          }
        )
      end

      it 'returns an error and does not create a version' do
        create(:ci_catalog_resource, project: project)

        response = execute

        expect(Ci::Catalog::Resources::Version.count).to be(0)
        expect(response).to be_error
        expect(response.message).to include('mapping values are not allowed in this context')
      end
    end
  end
end
