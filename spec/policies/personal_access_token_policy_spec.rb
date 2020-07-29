# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PersonalAccessTokenPolicy do
  include AdminModeHelper

  using RSpec::Parameterized::TableSyntax

  where(:user_type, :owned_by_same_user, :expected_permitted?) do
    :user  | true  | true
    :user  | false | false
    :admin | false | true
  end

  with_them do
    context 'determine if a token is readable by a user' do
      let(:user) { build_stubbed(user_type) }
      let(:token_owner) { owned_by_same_user ? user : build(:user) }
      let(:token) { build(:personal_access_token, user: token_owner) }

      subject { described_class.new(user, token) }

      before do
        enable_admin_mode!(user) if user.admin?
      end

      it { is_expected.to(expected_permitted? ? be_allowed(:read_token) : be_disallowed(:read_token)) }
    end
  end
end
