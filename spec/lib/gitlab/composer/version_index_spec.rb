# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Composer::VersionIndex do
  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:json) { { 'name' => package_name } }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :custom_repo, files: { 'composer.json' => json.to_json }, group: group) }
  let_it_be(:package1) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
  let_it_be(:package2) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }

  let(:branch) { project.repository.find_branch('master') }

  let(:packages) { [package1, package2] }

  describe '#as_json' do
    subject(:index) { described_class.new(packages).as_json }

    def expected_json(package)
      {
        'dist' => {
          'reference' => branch.target,
          'shasum' => '',
          'type' => 'zip',
          'url' => "http://localhost/api/v4/projects/#{project.id}/packages/composer/archives/#{package.name}.zip?sha=#{branch.target}"
        },
        'name' => package.name,
        'uid' => package.id,
        'version' => package.version
      }
    end

    it 'returns the packages json' do
      packages = index['packages'][package_name]

      expect(packages['1.0.0']).to eq(expected_json(package1))
      expect(packages['2.0.0']).to eq(expected_json(package2))
    end
  end

  describe '#sha' do
    subject(:sha) { described_class.new(packages).sha }

    it 'returns the json SHA' do
      expect(sha).to match /^[A-Fa-f0-9]{64}$/
    end
  end
end
