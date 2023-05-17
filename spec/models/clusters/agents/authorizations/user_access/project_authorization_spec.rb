# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::UserAccess::ProjectAuthorization, feature_category: :deployment_management do
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:project).class_name('Project').required }

  it { expect(described_class).to validate_jsonb_schema(['config']) }

  describe '.for_user' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:project) { create(:project) }
    let_it_be(:authorization) { create(:agent_user_access_project_authorization, project: project) }

    let(:user) { create(:user) }

    subject { described_class.for_user(user) }

    where(:user_role, :expected_access_level) do
      :guest       | nil
      :reporter    | nil
      :developer   | Gitlab::Access::DEVELOPER
      :maintainer  | Gitlab::Access::MAINTAINER
      :owner       | Gitlab::Access::OWNER
    end

    with_them do
      before do
        project.add_member(user, user_role)
      end

      it 'returns the expected result' do
        if expected_access_level
          expect(subject).to contain_exactly(authorization)
          expect(subject.first.access_level).to eq(expected_access_level)
        else
          expect(subject).to be_empty
        end
      end
    end
  end

  describe '#config_project' do
    let(:record) { create(:agent_user_access_project_authorization) }

    it { expect(record.config_project).to eq(record.agent.project) }
  end
end
