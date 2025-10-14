# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Composer::PackagesPresenter do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:package_name) { 'sample-project' }
  let_it_be(:json) { { 'name' => package_name } }
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, :public, :custom_repo, files: { 'composer.json' => json.to_json }, group: group) }
  let_it_be(:package1_sti) { create(:composer_package_sti, :with_metadatum, project: project, name: package_name, version: '1.0.0', json: json) }
  let_it_be(:package2_sti) { create(:composer_package_sti, :with_metadatum, project: project, name: package_name, version: '2.0.0', json: json) }
  let_it_be(:package1) { ::Packages::Composer::Package.find(package1_sti.id) }
  let_it_be(:package2) { ::Packages::Composer::Package.find(package2_sti.id) }

  let(:branch) { project.repository.find_branch('master') }

  let(:packages) { [package1, package2] }
  let(:is_v2) { false }
  let(:presenter) { described_class.new(group, packages, is_v2) }

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
        'source' => {
          'reference' => branch.target,
          'type' => 'git',
          'url' => "http://localhost/#{group.path}/#{project.path}.git"
        },
        'name' => package.name,
        'uid' => package.id,
        'version' => package.version
      }
    end

    it 'returns the packages json' do
      result = subject['packages'][package_name]

      expect(result['1.0.0']).to eq(expected_json(packages[0]))
      expect(result['2.0.0']).to eq(expected_json(packages[1]))
    end

    # TODO: Remove with the rollout of the FF packages_composer_read_from_detached_table
    # https://gitlab.com/gitlab-org/gitlab/-/issues/562123
    context 'with Packages::Composer::Sti::Package instances' do
      let(:packages) { [package1_sti, package2_sti] }

      it 'returns the packages json' do
        result = subject['packages'][package_name]

        expect(result['1.0.0']).to eq(expected_json(packages[0]))
        expect(result['2.0.0']).to eq(expected_json(packages[1]))
      end
    end
  end

  describe '#provider' do
    subject { presenter.provider }

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

    # TODO: Remove with the rollout of the FF packages_composer_read_from_detached_table
    # https://gitlab.com/gitlab-org/gitlab/-/issues/562123
    context 'with Packages::Composer::Sti::Package instances' do
      let(:packages) { [package1_sti, package2_sti] }

      it 'returns the provider json' do
        expect(subject).to match(expected_json)
      end
    end
  end

  describe '#root' do
    subject { presenter.root }

    let(:expected_json) do
      {
        'packages' => [],
        'provider-includes' => { 'p/%hash%.json' => { 'sha256' => /^\h+$/ } },
        'providers-url' => "prefix/api/v4/group/#{group.id}/-/packages/composer/%package%$%hash%.json",
        'metadata-url' => "prefix/api/v4/group/#{group.id}/-/packages/composer/p2/%package%.json"
      }
    end

    before do
      stub_config(gitlab: { relative_url_root: 'prefix' })
    end

    it 'returns the provider json' do
      expect(subject).to match(expected_json)
    end

    # TODO: Remove with the rollout of the FF packages_composer_read_from_detached_table
    # https://gitlab.com/gitlab-org/gitlab/-/issues/562123
    context 'with Packages::Composer::Sti::Package instances' do
      let(:packages) { [package1_sti, package2_sti] }

      it 'returns the provider json' do
        expect(subject).to match(expected_json)
      end
    end

    context 'with a client version 2' do
      let(:is_v2) { true }
      let(:expected_json) do
        {
          'packages' => [],
          'metadata-url' => "prefix/api/v4/group/#{group.id}/-/packages/composer/p2/%package%.json"
        }
      end

      it 'returns the provider json' do
        expect(subject).to match(expected_json)
      end
    end
  end
end
