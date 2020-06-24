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

    %w[saml cas3].each do |provider_name|
      context "when provider is #{provider_name}" do
        let(:provider) { provider_name }

        it { is_expected.to be_allowed(:link) }
        it { is_expected.not_to be_allowed(:unlink) }
      end
    end
  end
end
