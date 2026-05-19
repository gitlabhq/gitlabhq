# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ServiceAccount, feature_category: :user_management do
  subject(:service_account_entity) { described_class.new(service_account).as_json }

  let(:service_account) { build(:user, :service_account) }

  it 'exposes correct attributes' do
    expect(service_account_entity.keys).to contain_exactly(:email, :id, :name, :public_email, :username)
  end
end
