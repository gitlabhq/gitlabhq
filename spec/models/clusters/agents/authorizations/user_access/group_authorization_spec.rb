# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Clusters::Agents::Authorizations::UserAccess::GroupAuthorization, feature_category: :deployment_management do
  it { is_expected.to belong_to(:agent).class_name('Clusters::Agent').required }
  it { is_expected.to belong_to(:group).class_name('::Group').required }

  it { expect(described_class).to validate_jsonb_schema(['config']) }

  describe '.for_user' do
    using RSpec::Parameterized::TableSyntax

    let_it_be(:group) { create(:group) }
    let_it_be(:subgroup) { create(:group, parent: group) }

    let!(:authorization) { create(:agent_user_access_group_authorization, group: group) }
    let(:user) { create(:user) }

    subject { described_class.for_user(user) }

    context 'when user is member' do
      where(:user_role, :expected_access_level) do
        :guest       | nil
        :reporter    | nil
        :developer   | Gitlab::Access::DEVELOPER
        :maintainer  | Gitlab::Access::MAINTAINER
        :owner       | Gitlab::Access::OWNER
      end

      with_them do
        before do
          group.add_member(user, user_role)
        end

        it 'returns the expected result' do
          if expected_access_level
            expect(subject).to contain_exactly(authorization)
            expect(subject.first.access_level).to eq(expected_access_level)
          else
            expect(subject).to be_empty
          end
        end

        context 'when authorization belongs to sub-group' do
          let!(:authorization) { create(:agent_user_access_group_authorization, group: subgroup) }

          it 'respects the role inheritance' do
            if expected_access_level
              expect(subject).to contain_exactly(authorization)
              expect(subject.first.access_level).to eq(expected_access_level)
            else
              expect(subject).to be_empty
            end
          end

          it 'respects the role override' do
            subgroup.add_member(user, :owner)

            expect(subject).to contain_exactly(authorization)
            expect(subject.first.access_level).to eq(Gitlab::Access::OWNER)
          end
        end
      end
    end

    shared_examples 'does not yield an authorization' do
      it { expect(subject).to be_empty }
    end

    context 'when user is blocked' do
      let(:user) { create(:user, :blocked) }

      before do
        group.add_member(user, Gitlab::Access::MAINTAINER)
      end

      it_behaves_like 'does not yield an authorization'
    end

    context 'when user is banned' do
      let(:user) { create(:user, :banned) }

      before do
        group.add_member(user, Gitlab::Access::MAINTAINER)
      end

      it_behaves_like 'does not yield an authorization'
    end

    context 'when user requested access' do
      let!(:invited) { create(:group_member, :access_request, group: group, user: user) }

      it_behaves_like 'does not yield an authorization'
    end

    context 'when user is awaiting' do
      let!(:invited) { create(:group_member, :awaiting, group: group, user: user) }

      it_behaves_like 'does not yield an authorization'
    end
  end

  describe '#config_project' do
    let(:record) { create(:agent_user_access_group_authorization) }

    it { expect(record.config_project).to eq(record.agent.project) }
  end
end
