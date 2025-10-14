# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Cargo, feature_category: :package_registry do
  describe '.normalize_name' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :expected) do
      'MyPackage'       | 'mypackage'
      'my_package'      | 'my-package'
      'my_package_name' | 'my-package-name'
      'My_Package_Name' | 'my-package-name'
      'my_package_123'  | 'my-package-123'
      'my-package-name' | 'my-package-name'
      ''                | ''
      'A'               | 'a'
      'my__package'     | 'my--package'
    end

    with_them do
      it 'converts to lowercase and replaces underscores with hyphens' do
        expect(described_class.normalize_name(input)).to eq(expected)
      end
    end
  end

  describe '.normalize_version' do
    using RSpec::Parameterized::TableSyntax

    where(:input, :expected) do
      '1.0.0+build123'            | '1.0.0'
      '1.0.0'                     | '1.0.0'
      '1.0.0+git.abc123.build456' | '1.0.0'
      '1.0.0-alpha.1+build123'    | '1.0.0-alpha.1'
      '1.0.0+build+123'           | '1.0.0'
      '1.0.0+build.123.abc'       | '1.0.0'
      ''                          | ''
      '+build123'                 | ''
      '1.0.0+build123+extra456'   | '1.0.0'
    end

    with_them do
      it 'removes build metadata from version' do
        expect(described_class.normalize_version(input)).to eq(expected)
      end
    end
  end
end
