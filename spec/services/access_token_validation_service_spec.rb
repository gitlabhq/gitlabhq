require 'spec_helper'

describe AccessTokenValidationService, services: true do

  describe ".sufficient_scope?" do
    it "returns true if the required scope is present in the token's scopes" do
      token = double("token", scopes: [:api, :read_user])

      expect(described_class.sufficient_scope?(token, [:api])).to be(true)
    end

    it "returns true if more than one of the required scopes is present in the token's scopes" do
      token = double("token", scopes: [:api, :read_user, :other_scope])

      expect(described_class.sufficient_scope?(token, [:api, :other_scope])).to be(true)
    end

    it "returns true if the list of required scopes is an exact match for the token's scopes" do
      token = double("token", scopes: [:api, :read_user, :other_scope])

      expect(described_class.sufficient_scope?(token, [:api, :read_user, :other_scope])).to be(true)
    end

    it "returns true if the list of required scopes contains all of the token's scopes, in addition to others" do
      token = double("token", scopes: [:api, :read_user])

      expect(described_class.sufficient_scope?(token, [:api, :read_user, :other_scope])).to be(true)
    end

    it 'returns true if the list of required scopes is blank' do
      token = double("token", scopes: [])

      expect(described_class.sufficient_scope?(token, [])).to be(true)
    end

    it "returns false if there are no scopes in common between the required scopes and the token scopes" do
      token = double("token", scopes: [:api, :read_user])

      expect(described_class.sufficient_scope?(token, [:other_scope])).to be(false)
    end
  end
end
