# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::Catalog::Resources::ReleaseService, feature_category: :pipeline_composition do
  describe '#execute' do
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
        project = create(:project, :catalog_resource_with_components)
        release = create(:release, project: project, sha: project.repository.root_ref_sha)

        expect(histogram).to receive(:observe).with({}, an_instance_of(Float))

        described_class.new(release).execute
      end
    end

    context 'with a valid catalog resource and release' do
      it 'validates the catalog resource and creates a version' do
        project = create(:project, :catalog_resource_with_components)
        catalog_resource = create(:ci_catalog_resource, project: project)
        release = create(:release, project: project, sha: project.repository.root_ref_sha, tag: '1.0.0')

        response = described_class.new(release).execute

        version = Ci::Catalog::Resources::Version.last

        expect(response).to be_success
        expect(version.release).to eq(release)
        expect(version.catalog_resource).to eq(catalog_resource)
        expect(version.catalog_resource.project).to eq(project)
      end
    end

    context 'when the validation of the catalog resource fails' do
      it 'returns an error and does not create a version' do
        project = create(:project, :repository)
        create(:ci_catalog_resource, project: project)
        release = create(:release, project: project, sha: project.repository.root_ref_sha)

        response = described_class.new(release).execute

        expect(Ci::Catalog::Resources::Version.count).to be(0)
        expect(response).to be_error
        expect(response.message).to eq(
          'Project must have a description, ' \
          'Project must contain components. Ensure you are using the correct directory structure')
      end
    end

    context 'when the creation of a version fails' do
      it 'returns an error and does not create a version' do
        project =
          create(
            :project, :custom_repo,
            description: 'Component project',
            files: {
              'templates/secret-detection.yml' => 'image: agent: coop',
              'README.md' => 'Read me'
            }
          )
        create(:ci_catalog_resource, project: project)
        release = create(:release, project: project, sha: project.repository.root_ref_sha)

        response = described_class.new(release).execute

        expect(Ci::Catalog::Resources::Version.count).to be(0)
        expect(response).to be_error
        expect(response.message).to include('mapping values are not allowed in this context')
      end
    end
  end
end
