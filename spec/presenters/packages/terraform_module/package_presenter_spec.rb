# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::TerraformModule::PackagePresenter, feature_category: :package_registry do
  describe '#as_json' do
    # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need associations
    let_it_be(:project) { create(:project) }
    let_it_be(:another_project) { create(:project) }
    let_it_be(:user) { create(:user) }
    let_it_be(:pipeline) { create(:ci_pipeline, project: project, user: user) }
    let_it_be(:package) { create(:terraform_module_package, :with_metadatum, pipelines: [pipeline], project: project) }
    # rubocop:enable RSpec/FactoryBot/AvoidCreate

    let_it_be(:package_file) { package.package_files.first }

    let(:pipeline_hash) do
      pipeline
        .as_json(only: %i[created_at id sha ref])
        .merge(
          'project' => {
            'name' => project.name,
            'web_url' => ::Gitlab::Routing.url_helpers.project_url(project),
            'pipeline_url' => ::Gitlab::Routing.url_helpers.project_pipeline_url(project, pipeline),
            'commit_url' => ::Gitlab::Routing.url_helpers.project_commit_url(project, pipeline.sha)
          },
          'user' => {
            'avatar_url' => user.avatar_url,
            'name' => user.name
          }
        )
    end

    let(:result) do
      package.as_json.merge(
        'terraform_module_metadatum' => package.terraform_module_metadatum.as_json,
        'package_files' => [
          package_file.as_json.merge(
            'download_path' => package_file.download_path,
            'pipelines' => [pipeline_hash]
          )
        ],
        'pipeline' => pipeline_hash,
        'pipelines' => [pipeline_hash]
      )
    end

    before_all do
      package_file.package_file_build_infos.create!(pipeline: pipeline)
    end

    subject(:present) { described_class.new(package).as_json }

    it { is_expected.to include(result) }

    it 'avoids N+1 database queries' do
      # reset associations cache
      package.reload

      count = ActiveRecord::QueryRecorder.new { present }.count

      # rubocop:disable RSpec/FactoryBot/AvoidCreate -- Need associations
      create(:package_file, :terraform_module, package: package,
        pipelines: [create(:ci_pipeline, project: another_project)])
      # rubocop:enable RSpec/FactoryBot/AvoidCreate

      # reset associations cache
      package.reload

      expect do
        described_class.new(package).as_json
      end.not_to exceed_query_limit(count)
    end
  end
end
