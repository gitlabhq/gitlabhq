# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Detail::PackagePresenter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project, creator: user) }
  let_it_be(:package) { create(:npm_package, :with_build, project: project) }
  let(:presenter) { described_class.new(package) }

  let_it_be(:user_info) { { name: user.name, avatar_url: user.avatar_url } }

  let!(:expected_package_files) do
    package.package_files.map do |file|
      {
        created_at: file.created_at,
        download_path: file.download_path,
        file_name: file.file_name,
        size: file.size,
        file_md5: file.file_md5,
        file_sha1: file.file_sha1,
        file_sha256: file.file_sha256,
        id: file.id
      }
    end
  end

  let(:pipeline_info) do
    pipeline = package.original_build_info.pipeline
    {
      created_at: pipeline.created_at,
      id: pipeline.id,
      sha: pipeline.sha,
      ref: pipeline.ref,
      user: user_info,
      project: {
        name: pipeline.project.name,
        web_url: pipeline.project.web_url,
        pipeline_url: include("pipelines/#{pipeline.id}"),
        commit_url: include("commit/#{pipeline.sha}")
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
      status: package.status,
      project_id: package.project_id,
      tags: package.tags.as_json,
      updated_at: package.updated_at,
      version: package.version,
      dependency_links: dependency_links
    }
  end

  describe '#detail_view' do
    context 'with build_info' do
      let_it_be(:package) { create(:npm_package, :with_build, project: project) }

      let(:expected_package_details) do
        super().merge(
          pipeline: pipeline_info,
          pipelines: [pipeline_info]
        )
      end

      it 'returns details with pipeline' do
        expect(presenter.detail_view).to match expected_package_details
      end
    end

    context 'with multiple build_infos' do
      let_it_be(:package) { create(:npm_package, :with_build, project: project) }
      let_it_be(:build_info2) { create(:package_build_info, :with_pipeline, package: package) }

      it 'returns details with two pipelines' do
        expect(presenter.detail_view[:pipelines].size).to eq(2)
      end
    end

    context 'with package_file_build_infos' do
      let_it_be(:package) { create(:npm_package, :with_build, project: project) }

      let_it_be(:package_file_build_info) do
        create(:package_file_build_info, package_file: package.package_files.first,
                                         pipeline: package.pipelines.first)
      end

      it 'returns details with package_file pipeline' do
        expect(presenter.detail_view[:package_files].first[:pipelines].size).to eq(1)
      end
    end

    context 'without build info' do
      let_it_be(:package) { create(:npm_package, project: project) }

      it 'returns details without pipeline' do
        expect(presenter.detail_view).to eq expected_package_details
      end
    end

    context 'with conan metadata' do
      let(:package) { create(:conan_package, project: project) }
      let(:expected_package_details) { super().merge(conan_metadatum: package.conan_metadatum, conan_package_name: package.name, name: package.conan_recipe) }

      it 'returns conan_metadatum' do
        expect(presenter.detail_view).to eq expected_package_details
      end
    end

    context 'with composer metadata' do
      let(:package) { create(:composer_package, :with_metadatum, sha: '123', project: project) }
      let(:expected_package_details) { super().merge(composer_metadatum: package.composer_metadatum) }

      it 'returns composer_metadatum' do
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
