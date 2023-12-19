# frozen_string_literal: true

require 'spec_helper'

RSpec.describe BitbucketServer::Representation::User, feature_category: :importers do
  let(:email) { 'test@email.com' }
  let(:username) { 'test_user' }
  let(:sample_data) { { 'user' => { 'emailAddress' => email, 'slug' => username } } }

  subject(:user) { described_class.new(sample_data) }

  describe '#email' do
    it { expect(user.email).to eq(email) }
  end

  describe '#username' do
    it { expect(user.username).to eq(username) }
  end
end
