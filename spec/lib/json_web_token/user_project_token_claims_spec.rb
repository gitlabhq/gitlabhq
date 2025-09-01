# frozen_string_literal: true

require 'spec_helper'

RSpec.describe JSONWebToken::UserProjectTokenClaims, feature_category: :shared do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:namespace) { project.namespace }

  describe "#generate" do
    subject(:all_claims) { described_class.new(project: project, user: user).generate }

    it 'generates JWT project claims' do
      expect(all_claims).to include(
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
  end

  describe "#user_claims" do
    subject(:user_claims) { described_class.new(project: project, user: user).user_claims }

    it 'generates JWT user claims' do
      expect(user_claims).to include(
        user_id: user.id.to_s,
        user_login: user.username,
        user_email: user.email,
        user_access_level: nil
      )
    end

    context 'without user' do
      let_it_be(:user) { nil }

      it 'generates JWT project claims' do
        expect(user_claims).to include(
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
        expect(user_claims[:user_access_level]).to eq('developer')
      end
    end
  end

  describe "#project_claims" do
    let(:key_prefix) { '' }

    subject(:project_claims) do
      described_class.new(project: project, user: user).project_claims(key_prefix: key_prefix)
    end

    it 'generates JWT project claims' do
      expect(project_claims).to include(
        project_id: project.id.to_s,
        project_path: project.full_path,
        namespace_id: namespace.id.to_s,
        namespace_path: namespace.full_path
      )
    end

    context 'with key prefix' do
      let(:key_prefix) { 'test_' }

      subject(:project_claims) do
        described_class.new(project: project, user: user).project_claims(key_prefix: key_prefix)
      end

      it 'generates JWT project claims with key prefix' do
        expect(project_claims).to include(
          test_project_id: project.id.to_s,
          test_project_path: project.full_path,
          test_namespace_id: namespace.id.to_s,
          test_namespace_path: namespace.full_path
        )
      end
    end
  end
end
