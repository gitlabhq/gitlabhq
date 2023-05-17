# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IdentityProviderPolicy do
  subject(:policy) { described_class.new(user, provider) }

  let(:user) { User.new }
  let(:provider) { :a_provider }

  describe '#rules' do
    it { is_expected.to be_allowed(:link) }
    it { is_expected.to be_allowed(:unlink) }

    context 'when user is anonymous' do
      let(:user) { nil }

      it { is_expected.not_to be_allowed(:link) }
      it { is_expected.not_to be_allowed(:unlink) }
    end

    context "when provider is saml" do
      let(:provider) { 'saml' }

      it { is_expected.to be_allowed(:link) }
      it { is_expected.not_to be_allowed(:unlink) }
    end
  end
end
