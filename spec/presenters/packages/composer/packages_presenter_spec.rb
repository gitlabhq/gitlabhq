# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Composer::PackagesPresenter do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:json) { { 'name' => package_name } }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :custom_repo, files: { 'composer.json' => json.to_json }, group: group) }
  let_it_be(:package1) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
  let_it_be(:package2) { create(:composer_package, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }

  let(:branch) { project.repository.find_branch('master') }

  let(:packages) { [package1, package2] }
  let(:presenter) { described_class.new(group, packages) }

  describe '#package_versions' do
    subject { presenter.package_versions }

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
      packages = subject['packages'][package_name]

      expect(packages['1.0.0']).to eq(expected_json(package1))
      expect(packages['2.0.0']).to eq(expected_json(package2))
    end
  end

  describe '#provider' do
    subject { presenter.provider}

    let(:expected_json) do
      {
        'providers' => {
          package_name => {
            'sha256' => /^\h+$/
          }
        }
      }
    end

    it 'returns the provider json' do
      expect(subject).to match(expected_json)
    end
  end

  describe '#root' do
    subject { presenter.root }

    let(:expected_json) do
      {
        'packages' => [],
        'provider-includes' => { 'p/%hash%.json' => { 'sha256' => /^\h+$/ } },
        'providers-url' => "/api/v4/group/#{group.id}/-/packages/composer/%package%.json"
      }
    end

    it 'returns the provider json' do
      expect(subject).to match(expected_json)
    end
  end
end
