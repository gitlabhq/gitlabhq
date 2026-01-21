# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Authn::ScopedUserExtractor, feature_category: :system_access do
  describe '.extract_user_id_from_scopes' do
    subject(:extract_user_id) { described_class.extract_user_id_from_scopes(scopes) }

    context 'when scopes contain exactly one user scope' do
      let(:scopes) { %w[api user:123 read_repository] }

      it { is_expected.to eq(123) }
    end

    context 'when scopes contain no user scope' do
      let(:scopes) { %w[api read_repository] }

      it { is_expected.to be_nil }
    end

    context 'when scopes contain multiple user scopes' do
      let(:scopes) { %w[api user:123 user:456] }

      it { is_expected.to be_nil }
    end

    context 'when scopes is empty' do
      let(:scopes) { [] }

      it { is_expected.to be_nil }
    end

    context 'when user scope has invalid format' do
      let(:scopes) { %w[api user:abc read_repository] }

      it { is_expected.to be_nil }
    end
  end
end
