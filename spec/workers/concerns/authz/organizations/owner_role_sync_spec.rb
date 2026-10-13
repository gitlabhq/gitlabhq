# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::Organizations::OwnerRoleSync, feature_category: :system_access do
  using RSpec::Parameterized::TableSyntax

  describe '.enabled?' do
    where(:configured, :available, :expected) do
      true  | true  | true
      true  | false | false
      false | true  | false
      false | false | false
    end

    with_them do
      before do
        allow(Authn::IamDataAccessService).to receive(:configured?).and_return(configured)
        allow(Authn::TokenExchange::TokenIssuer).to receive(:available?).and_return(available)
      end

      it { expect(described_class.enabled?).to be(expected) }
    end
  end
end
