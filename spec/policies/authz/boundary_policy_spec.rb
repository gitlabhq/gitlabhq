# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Authz::BoundaryPolicy, feature_category: :permissions do
  let_it_be(:project) { create(:project) }
  let_it_be(:boundary) { Authz::Boundary.for(project) }
  let_it_be(:permissions) { ::Authz::Permission.all.keys }
  let_it_be(:token) { create(:granular_pat, namespace: boundary.namespace, permissions: permissions) }

  subject(:policy) { described_class.new(token, boundary) }

  context 'when the policy actor is not a PAT' do
    let(:token) { create(:oauth_access_token) }

    it { is_expected.to be_disallowed(*permissions) }
  end

  context 'when the PAT is not granular' do
    before do
      token.granular = false
    end

    it { is_expected.to be_disallowed(*permissions) }
  end

  context 'when a permission is not allowed' do
    it { is_expected.to be_disallowed(:not_allowed_permission) }
  end

  it { is_expected.to be_allowed(*permissions) }
end
