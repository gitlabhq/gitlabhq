# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Conan::PackagePresenter do
  let_it_be(:user) { create(:user) }
  let_it_be(:package) { create(:conan_package) }
  let_it_be(:project) { package.project }
  let_it_be(:conan_package_reference) { '123456789'}

  let(:params) { { package_scope: :instance } }

  shared_examples 'no existing package' do
    context 'when package does not exist' do
      let(:package) { nil }

      it { is_expected.to be_empty }
    end
  end

  shared_examples 'conan_file_metadatum is not found' do
    context 'when no conan_file_metadatum exists' do
      before do
        package.package_files.each do |file|
          file.conan_file_metadatum.delete
          file.reload
        end
      end

      it { is_expected.to be_empty }
    end
  end

  describe '#recipe_urls' do
    subject { described_class.new(package, user, project, params).recipe_urls }

    it_behaves_like 'no existing package'
    it_behaves_like 'conan_file_metadatum is not found'

    context 'existing package' do
      let(:expected_result) do
        {
          "conanfile.py" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanfile.py",
          "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
        }
      end

      it { is_expected.to eq(expected_result) }

      context 'when there are multiple channels for the same package' do
        let(:conan_metadatum) { create(:conan_metadatum, package_channel: 'newest' ) }
        let!(:newest_package) { create(:conan_package, name: package.name, version: package.version, project: project, conan_metadatum: conan_metadatum) }

        it { is_expected.to eq(expected_result) }
      end

      context 'with package_scope of project' do
        # #recipe_file_url checks for params[:id]
        let(:params) { { id: project.id } }

        let(:expected_result) do
          {
            "conanfile.py" => "#{Settings.build_base_gitlab_url}/api/v4/projects/#{project.id}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanfile.py",
            "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/projects/#{project.id}/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
          }
        end

        it { is_expected.to eq(expected_result) }
      end
    end
  end

  describe '#recipe_snapshot' do
    subject { described_class.new(package, user, project).recipe_snapshot }

    it_behaves_like 'no existing package'
    it_behaves_like 'conan_file_metadatum is not found'

    context 'existing package' do
      let(:expected_result) do
        {
          "conanfile.py" => '12345abcde',
          "conanmanifest.txt" => '12345abcde'
        }
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#package_urls' do
    let(:reference) { conan_package_reference }

    let(:params) do
      {
        conan_package_reference: reference,
        package_scope: :instance
      }
    end

    subject do
      described_class.new(
        package, user, project, params
      ).package_urls
    end

    it_behaves_like 'no existing package'
    it_behaves_like 'conan_file_metadatum is not found'

    context 'existing package' do
      let(:expected_result) do
        {
          "conaninfo.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conaninfo.txt",
          "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conanmanifest.txt",
          "conan_package.tgz" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conan_package.tgz"
        }
      end

      it { is_expected.to eq(expected_result) }

      context 'with package_scope of project' do
        # #package_file_url checks for params[:id]
        let(:params) do
          {
            conan_package_reference: reference,
            id: project.id
          }
        end

        let(:expected_result) do
          {
            "conaninfo.txt" => "#{Settings.build_base_gitlab_url}/api/v4/projects/#{project.id}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conaninfo.txt",
            "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/projects/#{project.id}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conanmanifest.txt",
            "conan_package.tgz" => "#{Settings.build_base_gitlab_url}/api/v4/projects/#{project.id}/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conan_package.tgz"
          }
        end

        it { is_expected.to eq(expected_result) }
      end

      context 'multiple packages with different references' do
        let(:info_file) { create(:conan_package_file, :conan_package_info, package: package) }
        let(:manifest_file) { create(:conan_package_file, :conan_package_manifest, package: package) }
        let(:package_file) { create(:conan_package_file, :conan_package, package: package) }
        let(:alternative_reference) { 'abcdefghi' }

        before do
          [info_file, manifest_file, package_file].each do |file|
            file.conan_file_metadatum.conan_package_reference = alternative_reference
            file.save!
          end
        end

        it { is_expected.to eq(expected_result) }

        context 'requesting the alternative reference' do
          let(:reference) { alternative_reference }

          let(:expected_result) do
            {
              "conaninfo.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{alternative_reference}/0/conaninfo.txt",
              "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{alternative_reference}/0/conanmanifest.txt",
              "conan_package.tgz" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{alternative_reference}/0/conan_package.tgz"
            }
          end

          it { is_expected.to eq(expected_result) }
        end

        it 'returns empty if the reference does not exist' do
          result = described_class.new(
            package, user, project, conan_package_reference: 'doesnotexist'
          ).package_urls

          expect(result).to eq({})
        end
      end
    end
  end

  describe '#package_snapshot' do
    let(:reference) { conan_package_reference }

    subject do
      described_class.new(
        package, user, project, conan_package_reference: reference
      ).package_snapshot
    end

    it_behaves_like 'no existing package'
    it_behaves_like 'conan_file_metadatum is not found'

    context 'existing package' do
      let(:expected_result) do
        {
          "conaninfo.txt" => '12345abcde',
          "conanmanifest.txt" => '12345abcde',
          "conan_package.tgz" => '12345abcde'
        }
      end

      it { is_expected.to eq(expected_result) }

      context 'when requested with invalid reference' do
        let(:reference) { 'invalid' }

        it { is_expected.to eq({}) }
      end
    end
  end
end
