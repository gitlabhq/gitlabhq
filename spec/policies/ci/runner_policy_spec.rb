# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Ci::RunnerPolicy, feature_category: :runner do
  let_it_be(:owner) { create(:user) }

  subject(:policy) { described_class.new(user, runner) }

  include_context 'with runner policy environment'

  describe 'ability :read_runner' do
    it_behaves_like 'runner policy not allowed for levels lower than maintainer', :read_runner
    it_behaves_like 'runner policy', :read_runner
  end

  describe 'ability :update_runner' do
    it_behaves_like 'runner policy not allowed for levels lower than maintainer', :update_runner

    context 'with maintainer access' do
      let(:user) { maintainer }

      it_behaves_like 'a policy disallowing access to instance runner/runner manager', :update_runner

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_disallowed :update_runner }
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_allowed :update_runner }

        context 'when user is maintainer in an unrelated group' do
          let_it_be(:maintainers_group_maintainer) { create(:user) }
          let_it_be_with_reload(:maintainers_group) do
            create(:group, name: 'maintainers', path: 'maintainers', maintainers: maintainers_group_maintainer)
          end

          let(:user) { maintainers_group_maintainer }

          it { expect_disallowed :update_runner }

          context 'when maintainers group is invited as maintainer to project' do
            before do
              create(:project_group_link, :maintainer, group: maintainers_group, project: project_invited_to)
            end

            context 'and target project is owner project' do
              let(:project_invited_to) { owner_project }

              it { expect_allowed :update_runner }
            end

            context 'and target project is other project' do
              let(:project_invited_to) { other_project }

              it { expect_disallowed :update_runner }
            end
          end
        end
      end
    end

    context 'with owner access' do
      let(:user) { owner }

      it_behaves_like 'a policy disallowing access to instance runner/runner manager', :update_runner

      context 'with group runner' do
        let(:runner) { group_runner }

        it { expect_allowed :update_runner }

        context 'with sharing of group runners disabled' do
          before do
            owner_project.update!(group_runners_enabled: false)
          end

          it { expect_allowed :update_runner }
        end

        context 'when access is provided by group invitation' do
          let_it_be(:invited_group) { create(:group) }
          let_it_be(:user) { create(:user, owner_of: invited_group) }

          it { expect_disallowed :update_runner }

          context 'when invited_group is invited to group' do
            before do
              create(:group_group_link, access_level, shared_group: group, shared_with_group: invited_group)
            end

            context 'as owner' do
              let(:access_level) { :owner }

              it { expect_allowed :update_runner }
            end

            context 'as maintainer' do
              let(:access_level) { :maintainer }

              it { expect_disallowed :update_runner }
            end
          end
        end
      end

      context 'with project runner' do
        let(:runner) { project_runner }

        it { expect_allowed :update_runner }
      end
    end
  end

  describe 'ability :read_ephemeral_token' do
    let_it_be(:runner) { create(:ci_runner, creator: owner) }

    let(:creator) { owner }

    context 'with request made by creator' do
      let(:user) { creator }

      it { expect_allowed :read_ephemeral_token }
    end

    context 'with request made by another user' do
      let(:user) { create(:admin) }

      it { expect_disallowed :read_ephemeral_token }
    end
  end
end
