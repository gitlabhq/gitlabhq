# frozen_string_literal: true

require "spec_helper"

RSpec.describe Files::BaseService, feature_category: :source_code_management do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:user) { create(:user, developer_of: group) }
  let(:params) { {} }

  subject(:author_email) { described_class.new(project, user, params).instance_variable_get(:@author_email) }

  context 'with no namespace_commit_emails' do
    it 'sets @author_email to user default email' do
      expect(author_email).to eq(user.email)
    end
  end

  context 'with an author_email in params and namespace_commit_email' do
    let(:params) { { author_email: 'email_from_params@example.com' } }

    before do
      create(:namespace_commit_email, user: user, namespace: group)
    end

    it 'gives precedence to the parameter value for @author_email' do
      expect(author_email).to eq('email_from_params@example.com')
    end
  end

  context 'with a project namespace_commit_email' do
    it 'sets @author_email to the project namespace_commit_email' do
      namespace_commit_email = create(:namespace_commit_email, user: user, namespace: project.project_namespace)

      expect(author_email).to eq(namespace_commit_email.email.email)
    end
  end

  context 'with a group namespace_commit_email' do
    it 'sets @author_email to the group namespace_commit_email' do
      namespace_commit_email = create(:namespace_commit_email, user: user, namespace: group)

      expect(author_email).to eq(namespace_commit_email.email.email)
    end
  end

  context 'with a project and group namespace_commit_email' do
    it 'sets @author_email to the project namespace_commit_email' do
      namespace_commit_email = create(:namespace_commit_email, user: user, namespace: project.project_namespace)
      create(:namespace_commit_email, user: user, namespace: group)

      expect(author_email).to eq(namespace_commit_email.email.email)
    end
  end
end
