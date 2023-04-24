# frozen_string_literal: true

require 'spec_helper'

RSpec.describe User, feature_category: :system_access do
  specify 'types consistency checks', :aggregate_failures do
    expect(described_class::USER_TYPES.keys)
      .to match_array(%w[human human_deprecated ghost alert_bot project_bot support_bot service_user security_bot
        visual_review_bot migration_bot automation_bot security_policy_bot admin_bot suggested_reviewers_bot
        service_account llm_bot])
    expect(described_class::USER_TYPES).to include(*described_class::BOT_USER_TYPES)
    expect(described_class::USER_TYPES).to include(*described_class::NON_INTERNAL_USER_TYPES)
    expect(described_class::USER_TYPES).to include(*described_class::INTERNAL_USER_TYPES)
  end

  describe 'scopes & predicates' do
    User::USER_TYPES.keys.each do |type| # rubocop:disable RSpec/UselessDynamicDefinition
      let_it_be(type) { create(:user, username: type, user_type: type) }
    end
    let(:bots) { User::BOT_USER_TYPES.map { |type| public_send(type) } }
    let(:non_internal) { User::NON_INTERNAL_USER_TYPES.map { |type| public_send(type) } }
    let(:everyone) { User::USER_TYPES.keys.map { |type| public_send(type) } }

    describe '.humans' do
      it 'includes humans only' do
        expect(described_class.humans).to match_array([human, human_deprecated])
      end
    end

    describe '.human' do
      it 'includes humans only' do
        expect(described_class.human).to match_array([human, human_deprecated])
      end
    end

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

    describe '.non_internal' do
      it 'includes all non_internal users' do
        expect(described_class.non_internal).to match_array(non_internal)
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

    describe '#human?' do
      it 'is true for humans only' do
        expect(human).to be_human
        expect(human_deprecated).to be_human
        expect(alert_bot).not_to be_human
        expect(User.new).to be_human
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
  end
end
