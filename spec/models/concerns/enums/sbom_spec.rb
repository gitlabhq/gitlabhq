# frozen_string_literal: true

require "spec_helper"

RSpec.describe Enums::Sbom, feature_category: :dependency_management do
  describe '.purl_types' do
    using RSpec::Parameterized::TableSyntax

    subject(:actual_purl_type) { described_class.purl_types[package_manager] }

    where(:given_package_manager, :expected_purl_type) do
      :composer             | 1
      'composer'            | 1
      :conan                | 2
      'conan'               | 2
      :gem                  | 3
      :golang               | 4
      :maven                | 5
      :npm                  | 6
      :nuget                | 7
      :pypi                 | 8
      :apk                  | 9
      :rpm                  | 10
      :deb                  | 11
      :cbl_mariner          | 12
      'unknown-pkg-manager' | 0
      'Python (unknown)'    | 0
    end

    with_them do
      let(:package_manager) { given_package_manager }

      it 'returns the expected purl_type' do
        expect(actual_purl_type).to eql(expected_purl_type)
      end
    end
  end
end
