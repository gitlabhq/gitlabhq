# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AccessTokenValidationService, feature_category: :system_access do
  describe ".include_any_scope?" do
    let(:request) { double("request") }

    it "returns true if the required scope is present in the token's scopes" do
      token = double("token", scopes: [:api, :read_user])
      scopes = [:api]

      expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(true)
    end

    it "returns true if more than one of the required scopes is present in the token's scopes" do
      token = double("token", scopes: [:api, :read_user, :other_scope])
      scopes = [:api, :other_scope]

      expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(true)
    end

    it "returns true if the list of required scopes is an exact match for the token's scopes" do
      token = double("token", scopes: [:api, :read_user, :other_scope])
      scopes = [:api, :read_user, :other_scope]

      expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(true)
    end

    it "returns true if the list of required scopes contains all of the token's scopes, in addition to others" do
      token = double("token", scopes: [:api, :read_user])
      scopes = [:api, :read_user, :other_scope]

      expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(true)
    end

    it 'returns true if the list of required scopes is blank' do
      token = double("token", scopes: [])
      scopes = []

      expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(true)
    end

    it "returns false if there are no scopes in common between the required scopes and the token scopes" do
      token = double("token", scopes: [:api, :read_user])
      scopes = [:other_scope]

      expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(false)
    end

    context "conditions" do
      it "ignores any scopes whose `if` condition returns false" do
        token = double("token", scopes: [:api, :read_user])
        scopes = [API::Scope.new(:api, if: ->(_) { false })]

        expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(false)
      end

      it "does not ignore scopes whose `if` condition is not set" do
        token = double("token", scopes: [:api, :read_user])
        scopes = [API::Scope.new(:api, if: ->(_) { false }), :read_user]

        expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(true)
      end

      it "does not ignore scopes whose `if` condition returns true" do
        token = double("token", scopes: [:api, :read_user])
        scopes = [API::Scope.new(:api, if: ->(_) { true }), API::Scope.new(:read_user, if: ->(_) { false })]

        expect(described_class.new(token, request: request).include_any_scope?(scopes)).to be(true)
      end
    end
  end
end
