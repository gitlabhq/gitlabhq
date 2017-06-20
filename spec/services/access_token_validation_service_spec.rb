require 'spec_helper'

describe AccessTokenValidationService, services: true do
  describe ".include_any_scope?" do
    let(:request) { double("request") }

    it "returns true if the required scope is present in the token's scopes" do
      token = double("token", scopes: [:api, :read_user])

      expect(described_class.new(token, request).include_any_scope?([{ name: :api }])).to be(true)
    end

    it "returns true if more than one of the required scopes is present in the token's scopes" do
      token = double("token", scopes: [:api, :read_user, :other_scope])

      expect(described_class.new(token, request).include_any_scope?([{ name: :api }, { name: :other_scope }])).to be(true)
    end

    it "returns true if the list of required scopes is an exact match for the token's scopes" do
      token = double("token", scopes: [:api, :read_user, :other_scope])

      expect(described_class.new(token, request).include_any_scope?([{ name: :api }, { name: :read_user }, { name: :other_scope }])).to be(true)
    end

    it "returns true if the list of required scopes contains all of the token's scopes, in addition to others" do
      token = double("token", scopes: [:api, :read_user])

      expect(described_class.new(token, request).include_any_scope?([{ name: :api }, { name: :read_user }, { name: :other_scope }])).to be(true)
    end

    it 'returns true if the list of required scopes is blank' do
      token = double("token", scopes: [])

      expect(described_class.new(token, request).include_any_scope?([])).to be(true)
    end

    it "returns false if there are no scopes in common between the required scopes and the token scopes" do
      token = double("token", scopes: [:api, :read_user])

      expect(described_class.new(token, request).include_any_scope?([{ name: :other_scope }])).to be(false)
    end

    context "conditions" do
      context "if" do
        it "ignores any scopes whose `if` condition returns false" do
          token = double("token", scopes: [:api, :read_user])

          expect(described_class.new(token, request).include_any_scope?([{ name: :api, if: ->(_) { false } }])).to be(false)
        end

        it "does not ignore scopes whose `if` condition is not set" do
          token = double("token", scopes: [:api, :read_user])

          expect(described_class.new(token, request).include_any_scope?([{ name: :api, if: ->(_) { false } }, { name: :read_user }])).to be(true)
        end

        it "does not ignore scopes whose `if` condition returns true" do
          token = double("token", scopes: [:api, :read_user])

          expect(described_class.new(token, request).include_any_scope?([{ name: :api, if: ->(_) { true } }, { name: :read_user, if: ->(_) { false } }])).to be(true)
        end
      end
    end
  end
end
