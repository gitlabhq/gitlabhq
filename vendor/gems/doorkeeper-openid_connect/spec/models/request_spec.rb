# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::Request do
  describe 'validations' do
    it 'requires an access grant' do
      subject.access_grant_id = nil

      expect(subject).not_to be_valid
      expect(subject.errors).to include :access_grant_id
    end

    it 'requires a nonce' do
      subject.nonce = nil

      expect(subject).not_to be_valid
      expect(subject.errors).to include :nonce
    end
  end

  describe 'associations' do
    it 'belongs to an access_grant' do
      association = subject.class.reflect_on_association :access_grant

      expect(association.options).to eq({
        class_name: 'Doorkeeper::AccessGrant',
        inverse_of: :openid_request,
      })
    end
  end
end
