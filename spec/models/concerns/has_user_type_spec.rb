# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User, feature_category: :system_access do
  User::USER_TYPES.each_key do |type| # rubocop:disable RSpec/UselessDynamicDefinition -- `type` used in `let`
    let_it_be(type) { create(:user, username: type, user_type: type) }
  end
  let(:bots) { User::BOT_USER_TYPES.map { |type| public_send(type) } }
  let(:non_internal) { User::NON_INTERNAL_USER_TYPES.map { |type| public_send(type) } }
  let(:everyone) { User::USER_TYPES.keys.map { |type| public_send(type) } }

  specify 'types consistency checks', :aggregate_failures do
    expect(described_class::USER_TYPES.keys)
      .to match_array(%w[human ghost alert_bot project_bot support_bot service_user security_bot
        visual_review_bot migration_bot automation_bot security_policy_bot admin_bot suggested_reviewers_bot
        service_account llm_bot placeholder duo_code_review_bot import_user])
    expect(described_class::USER_TYPES).to include(*described_class::BOT_USER_TYPES)
    expect(described_class::USER_TYPES).to include(*described_class::NON_INTERNAL_USER_TYPES)
    expect(described_class::USER_TYPES).to include(*described_class::INTERNAL_USER_TYPES)
  end

  describe 'validations' do
    it 'validates type presence' do
      expect(described_class.new).to validate_presence_of(:user_type)
    end
  end

  describe 'scopes & predicates' do
    describe '.bots' do
      it 'includes all bots' do
        expect(described_class.bots).to match_array(bots)
      end
    end

    describe '.without_bots' do
      it 'includes everyone except bots' do
        expect(described_class.without_bots).to match_array(everyone - bots)
      end
    end

    describe '.without_humans' do
      it 'includes everyone except humans' do
        expect(described_class.without_humans).to match_array(everyone - [human])
      end
    end

    describe '.non_internal' do
      it 'includes all non_internal users' do
        expect(described_class.non_internal).to match_array(non_internal)
      end
    end

    describe '.with_duo_code_review_bot' do
      it 'includes all non_internal and duo_code_review_bot users' do
        expect(described_class.with_duo_code_review_bot).to match_array(non_internal + [duo_code_review_bot])
      end
    end

    describe '.without_ghosts' do
      it 'includes everyone except ghosts' do
        expect(described_class.without_ghosts).to match_array(everyone - [ghost])
      end
    end

    describe '.without_project_bot' do
      it 'includes everyone except project_bot' do
        expect(described_class.without_project_bot).to match_array(everyone - [project_bot])
      end
    end

    describe '#bot?' do
      it 'is true for all bot user types and false for others' do
        expect(bots).to all(be_bot)

        (everyone - bots).each do |user|
          expect(user).not_to be_bot
        end
      end
    end

    describe '#internal?' do
      it 'is true for all internal user types and false for others' do
        expect(everyone - non_internal).to all(be_internal)

        non_internal.each do |user|
          expect(user).not_to be_internal
        end
      end
    end

    describe '#redacted_name(viewing_user)' do
      let_it_be(:viewing_user) { human }

      subject { observed_user.redacted_name(viewing_user) }

      context 'when user is not a project bot' do
        let(:observed_user) { support_bot }

        it { is_expected.to eq(support_bot.name) }
      end

      context 'when user is a project_bot' do
        let(:observed_user) { project_bot }

        context 'when groups are present and user can :read_group' do
          let_it_be(:group) { create(:group) }

          before do
            group.add_developer(observed_user)
            group.add_developer(viewing_user)
          end

          it { is_expected.to eq(observed_user.name) }
        end

        context 'when user can :read_project' do
          let_it_be(:project) { create(:project) }

          before do
            project.add_developer(observed_user)
            project.add_developer(viewing_user)
          end

          it { is_expected.to eq(observed_user.name) }
        end

        context 'when requester does not have permissions to read project_bot name' do
          it { is_expected.to eq('****') }
        end
      end
    end

    describe '#resource_bot_resource' do
      let_it_be(:group) { create(:group) }
      let_it_be(:group2) { create(:group) }
      let_it_be(:project) { create(:project) }
      let_it_be(:project2) { create(:project) }

      using RSpec::Parameterized::TableSyntax

      where(:bot_user, :member_of, :owning_resource) do
        ref(:human)       | [ref(:group)]                | nil
        ref(:project_bot) | []                           | nil # orphaned project bot
        ref(:project_bot) | [ref(:group)]                | ref(:group)
        ref(:project_bot) | [ref(:project)]              | ref(:project)

        # Project bot can only be added to one group or project.
        # That first group or project becomes the owning resource.
        ref(:project_bot) | [ref(:group), ref(:project)]    | ref(:group)
        ref(:project_bot) | [ref(:group), ref(:group2)]     | ref(:group)
        ref(:project_bot) | [ref(:project), ref(:group)]    | ref(:project)
        ref(:project_bot) | [ref(:project), ref(:project2)] | ref(:project)
      end

      with_them do
        before do
          member_of.each { |resource| resource.add_developer(bot_user) }
        end

        it 'returns the owning resource' do
          expect(bot_user.resource_bot_resource).to eq(owning_resource)
        end
      end
    end

    describe 'resource_bot_owners_and_maintainers' do
      it 'returns nil when user is not a project bot' do
        expect(human.resource_bot_resource).to be_nil
      end

      context 'when the user is a project bot' do
        let(:user1) { create(:user) }
        let(:user2) { create(:user) }

        subject(:owners_and_maintainers) { project_bot.resource_bot_owners_and_maintainers }

        it 'returns an empty array when there is no owning resource' do
          expect(owners_and_maintainers).to be_empty
        end

        it 'returns group owners when owned by a group' do
          group = create(:group)
          group.add_developer(project_bot)
          group.add_owner(user1)

          expect(owners_and_maintainers).to match_array([user1])
        end

        it 'returns project owners and maintainers when owned by a project' do
          project = create(:project)
          project.add_developer(project_bot)
          project.add_maintainer(user2)

          expect(owners_and_maintainers).to match_array([project.owner, user2])
        end

        it 'does not returns any other role than owner or maintainer' do
          project = create(:project)
          project.add_developer(project_bot)
          project.add_maintainer(user2)

          expect(owners_and_maintainers).not_to include(project_bot)
        end
      end
    end
  end
end
