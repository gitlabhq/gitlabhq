# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Parsers::Sbom::License::Common, feature_category: :dependency_management do
  context "with license information" do
    using RSpec::Parameterized::TableSyntax
    subject(:license) { described_class.parse(license_info) }

    where(:license_info, :expected_license) do
      { "license" => { "id" => "card-verifier" } } |
        { spdx_identifier: "card-verifier" }
      { "license" => { "id" => "card-verifier", "name" => "Card Verifier" } } |
        { spdx_identifier: "card-verifier", name: "Card Verifier" }
      { "license" => { "id" => "card-verifier", "name" => "Card Verifier", "url" => "https://card-verifier.com" } } |
        { spdx_identifier: "card-verifier", name: "Card Verifier", url: "https://card-verifier.com" }
      { "license" => { "name" => "EPL-2.0" } } |
        {}
      { "license" => { "name" => "BSD-2-Clause-NetBSD" } } |
        {}
      { "expression" => "EPL-2.0 OR GPL-2.0 WITH Classpath-exception-2.0" } |
        {}
    end

    with_them do
      it "sets the license information" do
        is_expected.to have_attributes(expected_license)
      end
    end
  end
end
