# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authn::Tokens::Concerns::DoorkeeperCompatible, feature_category: :system_access do
  let(:dummy_class) do
    Class.new do
      include Authn::Tokens::Concerns::DoorkeeperCompatible

      attr_accessor :user, :user_id, :expires_at, :raw_scopes, :revoked

      def revoked?
        !!revoked
      end
    end
  end

  let(:instance) { dummy_class.new }

  before do
    instance.user_id = 1
    instance.expires_at = 1.hour.from_now
    instance.raw_scopes = %w[api]
    instance.revoked = false
  end

  describe '#active?' do
    it 'is true when not expired and not revoked' do
      expect(instance).to be_active
    end

    it 'is false when expired' do
      instance.expires_at = 1.hour.ago

      expect(instance).not_to be_active
    end

    it 'is false when revoked' do
      instance.revoked = true

      expect(instance).not_to be_active
    end
  end

  describe '#accessible?' do
    it 'is true when active and the user is active' do
      instance.user = instance_double(User, active?: true)

      expect(instance).to be_accessible
    end

    it 'is false when the user is inactive' do
      instance.user = instance_double(User, active?: false)

      expect(instance).not_to be_accessible
    end
  end

  describe '#acceptable?' do
    before do
      instance.user = instance_double(User, active?: true)
    end

    it 'accepts a scope the token carries' do
      expect(instance.acceptable?('api')).to be(true)
    end

    it 'rejects a scope the token does not carry' do
      expect(instance.acceptable?('admin_mode')).to be(false)
    end
  end

  describe '#includes_scope?' do
    it 'is true when no scope is required' do
      expect(instance.includes_scope?).to be(true)
    end

    it 'is true when required_scopes is empty' do
      expect(instance.includes_scope?(*[])).to be(true)
    end

    it 'is true when at least one required scope matches' do
      expect(instance.includes_scope?('admin_mode', 'api')).to be(true)
    end

    it 'is false when none of the required scopes match' do
      expect(instance.includes_scope?('admin_mode', 'sudo')).to be(false)
    end
  end

  describe '#scopes' do
    it 'wraps raw_scopes in Doorkeeper::OAuth::Scopes' do
      expect(instance.scopes).to be_a(Doorkeeper::OAuth::Scopes)
      expect(instance.scopes.to_a).to contain_exactly('api')
    end
  end

  describe '#resource_owner_id' do
    it 'returns user_id' do
      expect(instance.resource_owner_id).to eq(1)
    end
  end

  describe '#application' do
    it 'returns nil' do
      expect(instance.application).to be_nil
    end
  end
end
