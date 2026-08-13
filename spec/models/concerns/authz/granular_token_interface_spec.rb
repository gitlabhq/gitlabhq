# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::GranularTokenInterface, feature_category: :permissions do
  let(:token_class) do
    Struct.new(:granular, :granular_scopes) do
      include Authz::GranularTokenInterface

      def granular?
        granular
      end
    end
  end

  def granular_scope(applicable:, permissions:)
    instance_double(Authz::GranularScope, applicable_to_boundary?: applicable, expanded_permissions: permissions)
  end

  describe 'PolicyActor' do
    it 'provides #can? to includers that do not define it themselves' do
      expect(token_class.new(true)).to respond_to(:can?)
    end
  end

  describe '#legacy?' do
    context 'when the token is granular' do
      it 'returns false' do
        expect(token_class.new(true).legacy?).to be(false)
      end
    end

    context 'when the token is not granular' do
      it 'returns true' do
        expect(token_class.new(false).legacy?).to be(true)
      end
    end
  end

  describe '#permitted_for_boundary?' do
    subject(:permitted_for_boundary) { token.permitted_for_boundary?(boundary, permissions) }

    let(:boundary) { instance_double(Authz::Boundary::Base) }
    let(:token) { token_class.new(true, [scope]) }
    let(:permissions) { [:create_issue] }

    context 'when the token is legacy' do
      let(:token) { token_class.new(false) }

      it { is_expected.to be(false) }
    end

    context 'when an applicable scope grants the required permissions' do
      let(:scope) { granular_scope(applicable: true, permissions: [:create_issue, :create_work_item]) }

      it { is_expected.to be(true) }
    end

    context 'when no scope is applicable to the boundary' do
      let(:scope) { granular_scope(applicable: false, permissions: [:create_issue]) }

      it { is_expected.to be(false) }
    end

    context 'when the applicable scopes do not grant all required permissions' do
      let(:permissions) { [:create_issue, :create_member_role] }
      let(:scope) { granular_scope(applicable: true, permissions: [:create_issue]) }

      it { is_expected.to be(false) }
    end

    context 'when permissions are given as strings' do
      let(:permissions) { 'create_issue' }
      let(:scope) { granular_scope(applicable: true, permissions: [:create_issue]) }

      it { is_expected.to be(true) }
    end
  end

  describe 'PersonalAccessToken' do
    it 'includes the interface' do
      expect(PersonalAccessToken.include?(described_class)).to be(true)
    end

    it 'provides every method of the granular token contract' do
      token = build_stubbed(:personal_access_token)

      expect(token).to respond_to(:granular?, :legacy?, :permitted_for_boundary?, :can?, :granular_scopes)
    end
  end
end
