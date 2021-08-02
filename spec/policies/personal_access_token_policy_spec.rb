# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokenPolicy do
  include AdminModeHelper

  subject { described_class.new(current_user, token) }

  context 'current_user is an administrator', :enable_admin_mode do
    let_it_be(:current_user) { build_stubbed(:admin) }

    context 'not the owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token) }

      it { is_expected.to be_allowed(:read_token) }
      it { is_expected.to be_allowed(:revoke_token) }
    end

    context 'owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user) }

      it { is_expected.to be_allowed(:read_token) }
      it { is_expected.to be_allowed(:revoke_token) }
    end
  end

  context 'current_user is not an administrator' do
    let_it_be(:current_user) { build_stubbed(:user) }

    context 'not the owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token) }

      it { is_expected.to be_disallowed(:read_token) }
      it { is_expected.to be_disallowed(:revoke_token) }
    end

    context 'owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user) }

      it { is_expected.to be_allowed(:read_token) }
      it { is_expected.to be_allowed(:revoke_token) }
    end

    context 'subject of the impersonated token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user, impersonation: true) }

      it { is_expected.to be_disallowed(:read_token) }
      it { is_expected.to be_disallowed(:revoke_token) }
    end
  end

  context 'current_user is a blocked administrator', :enable_admin_mode do
    let_it_be(:current_user) { create(:admin, :blocked) }

    context 'owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token, user: current_user) }

      it { is_expected.to be_disallowed(:read_token) }
      it { is_expected.to be_disallowed(:revoke_token) }
    end

    context 'not the owner of the token' do
      let_it_be(:token) { build_stubbed(:personal_access_token) }

      it { is_expected.to be_disallowed(:read_token) }
      it { is_expected.to be_disallowed(:revoke_token) }
    end
  end
end
