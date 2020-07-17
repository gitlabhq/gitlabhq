# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Conan::PackagePresenter do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let_it_be(:conan_package_reference) { '123456789'}

  RSpec.shared_examples 'not selecting a package with the wrong type' do
    context 'with a nuget package with same name and version' do
      let_it_be(:wrong_package) { create(:nuget_package, name: 'wrong', version: '1.0.0', project: project) }

      let(:recipe) { "#{wrong_package.name}/#{wrong_package.version}" }

      it { is_expected.to be_empty }
    end
  end

  describe '#recipe_urls' do
    subject { described_class.new(recipe, user, project).recipe_urls }

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    it_behaves_like 'not selecting a package with the wrong type'

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

      let(:expected_result) do
        {
          "conanfile.py" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanfile.py",
          "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/export/conanmanifest.txt"
        }
      end

      it { is_expected.to eq(expected_result) }
    end
  end

  describe '#recipe_snapshot' do
    subject { described_class.new(recipe, user, project).recipe_snapshot }

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    it_behaves_like 'not selecting a package with the wrong type'

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

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

    subject do
      described_class.new(
        recipe, user, project, conan_package_reference: reference
      ).package_urls
    end

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    it_behaves_like 'not selecting a package with the wrong type'

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

      let(:expected_result) do
        {
          "conaninfo.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conaninfo.txt",
          "conanmanifest.txt" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conanmanifest.txt",
          "conan_package.tgz" => "#{Settings.build_base_gitlab_url}/api/v4/packages/conan/v1/files/#{package.conan_recipe_path}/0/package/#{conan_package_reference}/0/conan_package.tgz"
        }
      end

      it { is_expected.to eq(expected_result) }

      context 'multiple packages with different references' do
        let(:info_file) { create(:conan_package_file, :conan_package_info, package: package) }
        let(:manifest_file) { create(:conan_package_file, :conan_package_manifest, package: package) }
        let(:package_file) { create(:conan_package_file, :conan_package, package: package) }
        let(:alternative_reference) { 'abcdefghi' }

        before do
          [info_file, manifest_file, package_file].each do |file|
            file.conan_file_metadatum.conan_package_reference = alternative_reference
            file.save
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
            recipe, user, project, conan_package_reference: 'doesnotexist'
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
        recipe, user, project, conan_package_reference: reference
      ).package_snapshot
    end

    context 'no existing package' do
      let(:recipe) { "my-pkg/v1.0.0/#{project.full_path}/stable" }

      it { is_expected.to be_empty }
    end

    it_behaves_like 'not selecting a package with the wrong type'

    context 'existing package' do
      let(:package) { create(:conan_package, project: project) }
      let(:recipe) { package.conan_recipe }

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
