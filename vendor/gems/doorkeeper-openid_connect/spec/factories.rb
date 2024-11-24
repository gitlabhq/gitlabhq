# frozen_string_literal: true

FactoryBot.define do
  factory :access_grant, class: 'Doorkeeper::AccessGrant' do
    resource_owner_id { create(:user).id }
    application
    redirect_uri { 'https://app.com/callback' }
    expires_in { 100 }
    scopes { 'public write' }
  end

  factory :access_token, class: 'Doorkeeper::AccessToken' do
    resource_owner_id { create(:user).id }
    application
    expires_in { 2.hours }

    factory :clientless_access_token do
      application { nil }
    end
  end

  factory :application, class: 'Doorkeeper::Application' do
    sequence(:name) { |n| "Application #{n}" }
    redirect_uri { 'https://app.com/callback' }
  end

  factory :user do
    current_sign_in_at { Time.zone.at(23) }
  end

  factory :openid_request, class: 'Doorkeeper::OpenidConnect::Request' do
    access_grant
    sequence(:nonce, &:to_s)
  end
end
