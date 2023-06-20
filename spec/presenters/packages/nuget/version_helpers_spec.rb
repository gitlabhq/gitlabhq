# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Packages::Nuget::VersionHelpers, feature_category: :package_registry do
  include described_class

  describe '#sort_versions' do
    using RSpec::Parameterized::TableSyntax

    where(:unsorted_versions, :expected_result) do
      ['1.0.0-a1b', '1.0.0-abb', '1.0.0-a11'] | ['1.0.0-a11', '1.0.0-a1b', '1.0.0-abb']

      ['1.8.6-10pre', '1.8.6-5pre', '1.8.6-05pre', '1.8.6-9'] | ['1.8.6-9', '1.8.6-05pre', '1.8.6-10pre', '1.8.6-5pre']

      ['8.4.0-MOR-4077-TabControl.1', '8.4.0-max-migration.1', '8.4.0-develop-nuget20230418.1',
        '8.4.0-MOR-4077-TabControl.2'] |
        ['8.4.0-develop-nuget20230418.1', '8.4.0-max-migration.1', '8.4.0-MOR-4077-TabControl.1',
          '8.4.0-MOR-4077-TabControl.2']

      ['1.0.0-beta+build.1', '1.0.0-beta.11', '1.0.0-beta.2', '1.0.0-alpha', '1.0.0-alpha.1', '1.0.0-alpha.2',
        '1.0.0-alpha.beta', '2.0.0', '1.0.0-rc.1', '1.0.0-beta', '2.0.0-alpha', '1.0.0', '1.0.0-rc.1+build.1',
        '1.0.0+build', '1.0.0+build.1', '1.0.1-rc.1', '1.0.1', '1.0.1+build.2', '1.1.0-alpha', '1.1.0'] |
        ['1.0.0-alpha', '1.0.0-alpha.1', '1.0.0-alpha.2', '1.0.0-alpha.beta', '1.0.0-beta', '1.0.0-beta+build.1',
          '1.0.0-beta.2', '1.0.0-beta.11', '1.0.0-rc.1', '1.0.0-rc.1+build.1', '1.0.0', '1.0.0+build', '1.0.0+build.1',
          '1.0.1-rc.1', '1.0.1', '1.0.1+build.2', '1.1.0-alpha', '1.1.0', '2.0.0-alpha', '2.0.0']
    end

    with_them do
      it 'sorts versions in ascending order' do
        expect(sort_versions(unsorted_versions)).to eq(expected_result)
        expect(VersionSorter.sort(unsorted_versions)).not_to eq(expected_result)
      end
    end
  end
end
