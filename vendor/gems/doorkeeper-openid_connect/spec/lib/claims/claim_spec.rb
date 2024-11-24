# frozen_string_literal: true

require 'rails_helper'

describe Doorkeeper::OpenidConnect::Claims::Claim do
  subject { described_class.new name: 'username', scope: 'profile' }

  describe '#initialize' do
    it 'uses the given name' do
      expect(subject.name).to eq :username
    end

    it 'uses the given scope' do
      expect(subject.scope).to eq :profile
    end

    it 'falls back to the default scope for standard claims' do
      expect(described_class.new(name: 'family_name').scope).to eq :profile
      expect(described_class.new(name: :family_name).scope).to eq :profile
      expect(described_class.new(name: 'email').scope).to eq :email
      expect(described_class.new(name: :email).scope).to eq :email
      expect(described_class.new(name: 'address').scope).to eq :address
      expect(described_class.new(name: :address).scope).to eq :address
      expect(described_class.new(name: 'phone_number').scope).to eq :phone
      expect(described_class.new(name: :phone_number).scope).to eq :phone
    end

    it 'falls back to the profile scope for non-standard claims' do
      expect(described_class.new(name: 'unknown').scope).to eq :profile
    end
  end
end
