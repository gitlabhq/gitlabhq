# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JSONWebToken::ProjectTokenClaims, feature_category: :shared do
  describe '#generate' do
    let_it_be(:user) { create(:user) }
    let_it_be(:project) { create(:project) }

    let(:namespace) { project.namespace }

    subject(:project_claims) { described_class.new(project: project, user: user).generate }

    it 'generates JWT project claims' do
      expect(project_claims).to include(
        namespace_id: namespace.id.to_s,
        namespace_path: namespace.full_path,
        project_id: project.id.to_s,
        project_path: project.full_path,
        user_id: user.id.to_s,
        user_login: user.username,
        user_email: user.email,
        user_access_level: nil
      )
    end

    context 'without user' do
      let_it_be(:user) { nil }

      it 'generates JWT project claims' do
        expect(project_claims).to include(
          user_id: '',
          user_login: nil,
          user_email: nil,
          user_access_level: nil
        )
      end
    end

    context 'with a developer role' do
      before_all do
        project.add_developer(user)
      end

      it 'has correct access level' do
        expect(project_claims[:user_access_level]).to eq('developer')
      end
    end
  end
end
