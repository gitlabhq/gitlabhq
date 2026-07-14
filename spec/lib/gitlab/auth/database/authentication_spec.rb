# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::Database::Authentication, feature_category: :system_access do
  let_it_be(:user) { create(:user) }

  describe '#login' do
    subject(:authentication) { described_class.new('database', user).login(login, password) }

    let(:login) { user.username }
    let(:password) { user.password }

    context 'when the password is valid' do
      it 'returns the user' do
        expect(authentication).to eq(user)
      end
    end

    context 'when the password is invalid' do
      let(:password) { 'wrong_password' }

      it 'returns nil' do
        expect(authentication).to be_nil
      end
    end

    context 'when the user is not provided' do
      subject(:authentication) { described_class.new('database').login(login, password) }

      it 'returns nil' do
        expect(authentication).to be_nil
      end
    end
  end
end
