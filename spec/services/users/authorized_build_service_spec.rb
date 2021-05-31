# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::AuthorizedBuildService do
  describe '#execute' do
    let_it_be(:current_user) { create(:user) }

    let(:params) { build_stubbed(:user).slice(:first_name, :last_name, :username, :email, :password) }

    subject(:user) { described_class.new(current_user, params).execute }

    it_behaves_like 'common user build items'
    it_behaves_like 'current user not admin build items'
  end
end
