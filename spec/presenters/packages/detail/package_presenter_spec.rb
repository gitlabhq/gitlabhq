# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Detail::PackagePresenter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user) }
  let_it_be(:package) { create(:npm_package, :with_build, project: project) }
  let(:presenter) { described_class.new(package) }

  let_it_be(:user_info) { { name: user.name, avatar_url: user.avatar_url } }
  let!(:expected_package_files) do
    npm_file = package.package_files.first
    [{
      created_at: npm_file.created_at,
      download_path: npm_file.download_path,
      file_name: npm_file.file_name,
      size: npm_file.size
    }]
  end
  let(:pipeline_info) do
    pipeline = package.build_info.pipeline
    {
      created_at: pipeline.created_at,
      id: pipeline.id,
      sha: pipeline.sha,
      ref: pipeline.ref,
      git_commit_message: pipeline.git_commit_message,
      user: user_info,
      project: {
        name: pipeline.project.name,
        web_url: pipeline.project.web_url
      }
    }
  end
  let!(:dependency_links) { [] }
  let!(:expected_package_details) do
    {
      id: package.id,
      created_at: package.created_at,
      name: package.name,
      package_files: expected_package_files,
      package_type: package.package_type,
      project_id: package.project_id,
      tags: package.tags.as_json,
      updated_at: package.updated_at,
      version: package.version,
      dependency_links: dependency_links
    }
  end

  context 'detail_view' do
    context 'with build_info' do
      let_it_be(:package) { create(:npm_package, :with_build, project: project) }
      let(:expected_package_details) { super().merge(pipeline: pipeline_info) }

      it 'returns details with pipeline' do
        expect(presenter.detail_view).to eq expected_package_details
      end
    end

    context 'without build info' do
      let_it_be(:package) { create(:npm_package, project: project) }

      it 'returns details without pipeline' do
        expect(presenter.detail_view).to eq expected_package_details
      end
    end

    context 'with nuget_metadatum' do
      let_it_be(:package) { create(:nuget_package, project: project) }
      let_it_be(:nuget_metadatum) { create(:nuget_metadatum, package: package) }
      let(:expected_package_details) { super().merge(nuget_metadatum: nuget_metadatum) }

      it 'returns nuget_metadatum' do
        expect(presenter.detail_view).to eq expected_package_details
      end
    end

    context 'with dependency_links' do
      let_it_be(:package) { create(:nuget_package, project: project) }
      let_it_be(:dependency_link) { create(:packages_dependency_link, package: package) }
      let_it_be(:nuget_dependency) { create(:nuget_dependency_link_metadatum, dependency_link: dependency_link) }
      let_it_be(:expected_link) do
        {
          name: dependency_link.dependency.name,
          version_pattern: dependency_link.dependency.version_pattern,
          target_framework: nuget_dependency.target_framework
        }
      end
      let_it_be(:dependency_links) { [expected_link] }

      it 'returns the correct dependency link' do
        expect(presenter.detail_view).to eq expected_package_details
      end
    end
  end
end
