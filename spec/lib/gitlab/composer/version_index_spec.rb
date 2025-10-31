# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Composer::VersionIndex, feature_category: :package_registry do
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:json) { { 'name' => package_name } }
  let_it_be(:group) { create(:group) }
  let_it_be(:files) { { 'composer.json' => json.to_json } }
  let_it_be_with_reload(:project) { create(:project, :public, :custom_repo, files: files, group: group) }
  let_it_be_with_reload(:package1_sti) { create(:composer_package_sti, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
  let_it_be_with_reload(:package2_sti) { create(:composer_package_sti, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }
  let_it_be_with_reload(:package1) { ::Packages::Composer::Package.find(package1_sti.id) }
  let_it_be_with_reload(:package2) { ::Packages::Composer::Package.find(package2_sti.id) }

  let(:url) { "http://localhost/#{group.path}/#{project.path}.git" }
  let(:branch) { project.repository.find_branch('master') }
  let(:packages) { [package1, package2] }

  describe '#as_json' do
    let(:index) { described_class.new(packages).as_json }
    let(:ssh_path_prefix) { 'username@localhost:' }

    subject(:package_index) { index['packages'][package_name] }

    before do
      allow(Gitlab.config.gitlab_shell).to receive(:ssh_path_prefix)
        .and_return(ssh_path_prefix)
    end

    shared_examples 'returns the packages json' do
      def expected_json(package)
        {
          'dist' => {
            'reference' => branch.target,
            'shasum' => '',
            'type' => 'zip',
            'url' => "http://localhost/api/v4/projects/#{project.id}/packages/composer/archives/#{package.name}.zip?sha=#{branch.target}"
          },
          'source' => {
            'reference' => branch.target,
            'type' => 'git',
            'url' => url
          },
          'name' => package.name,
          'uid' => package.id,
          'version' => package.version
        }
      end

      it 'returns the packages json' do
        expect(package_index['1.0.0']).to eq(expected_json(packages[0]))
        expect(package_index['2.0.0']).to eq(expected_json(packages[1]))
      end

      context 'with an unordered list of packages' do
        let(:packages) { [package2, package1] }

        it 'returns the packages sorted by version' do
          expect(package_index.keys).to eq ['1.0.0', '2.0.0']
        end
      end
    end

    context 'with a public project' do
      it_behaves_like 'returns the packages json'
    end

    context 'with an internal project' do
      let(:url) { "#{ssh_path_prefix}#{group.path}/#{project.path}.git" }

      before_all do
        project.update!(visibility: Gitlab::VisibilityLevel::INTERNAL)
      end

      it_behaves_like 'returns the packages json'
    end

    context 'with a private project' do
      let(:url) { "#{ssh_path_prefix}#{group.path}/#{project.path}.git" }

      before_all do
        project.update!(visibility: Gitlab::VisibilityLevel::PRIVATE)
      end

      it_behaves_like 'returns the packages json'
    end
  end

  describe '#sha' do
    subject(:sha) { described_class.new(packages).sha }

    it 'returns the json SHA' do
      expect(sha).to match(/^[A-Fa-f0-9]{64}$/)
    end
  end
end
