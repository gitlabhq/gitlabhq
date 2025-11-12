# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PackageVersion, feature_category: :package_registry do
  context 'without build info' do
    let_it_be(:package) { create(:generic_package) }

    subject { described_class.new(package).as_json(namespace: package.project.namespace) }

    it { is_expected.not_to include(:pipeline) }
    it { is_expected.to include(:id, :version, :created_at, :tags) }
  end

  context 'with build info', :aggregate_failures do
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:user) { create(:user, reporter_of: project) }
    let_it_be(:package) { create(:npm_package, :with_build, project: project) }
    let_it_be(:pipeline) { package.pipeline }
    let(:expected_data) do
      {
        id: pipeline.id,
        iid: pipeline.iid,
        sha: pipeline.sha,
        project_id: pipeline.project_id,
        ref: pipeline.ref,
        status: pipeline.status,
        source: pipeline.source
      }
    end

    subject(:package_version) { described_class.new(package).as_json(namespace: package.project.namespace, user: user) }

    it 'returns the pipeline' do
      expect(package_version[:pipeline]).to match(a_hash_including(expected_data))
    end

    context 'when repository access is disabled' do
      before do
        project.project_feature.update!(
          repository_access_level: ProjectFeature::DISABLED,
          merge_requests_access_level: ProjectFeature::DISABLED,
          builds_access_level: ProjectFeature::DISABLED
        )
      end

      it 'does not expose pipeline attribute' do
        expect(package_version).not_to include(:pipeline)
      end
    end

    context 'without a user' do
      let(:user) { nil }

      it { is_expected.not_to include(:pipeline) }
    end
  end
end
