# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Users::Internal, feature_category: :user_profile do
  let_it_be(:first_organization) { create(:organization) }
  let_it_be(:organization) { create(:organization) }

  shared_examples 'bot users' do |bot_type, username, email|
    subject(:bot_user) { described_class.for_organization(organization).public_send(bot_type) }

    let(:bot_username) do
      described_class.for_organization(organization).send(
        :username_with_organization_suffix, username
      )
    end

    it 'creates the user if it does not exist' do
      expect do
        described_class.for_organization(organization).public_send(bot_type)
      end.to change { User.where(user_type: bot_type).count }.by(1)
    end

    it 'creates a route for the namespace of the created user' do
      expect(bot_user.namespace.route).to be_present
      expect(bot_user.namespace.organization).to eq(organization)
    end

    it 'creates a user with a global username suffixed with the organization name' do
      expect(bot_user.username).to include(username)
      expect(bot_user.username).to include(organization.path)
      expect(bot_user.name).not_to include("(#{organization.name})")
    end

    it 'assigns the organization to the created user' do
      expect(bot_user.organizations).to eq([organization])
    end

    it 'creates an organization_user_detail with a per-organization username' do
      expect(bot_user.organization_user_details.count).to eq(1)

      detail = bot_user.organization_user_details.first
      expect(detail.username).to eq(username)
      expect(detail.display_name).to include("(#{organization.name})")
    end

    it 'does not create a new user if it already exists' do
      described_class.for_organization(organization).public_send(bot_type)

      expect do
        described_class.for_organization(organization).public_send(bot_type)
      end.not_to change { User.count }
    end

    context 'when a regular user exists with the bot username' do
      let!(:user) { create(:user, :with_namespace, username: bot_username) }

      it 'creates a user with a non-conflicting username' do
        expect do
          bot_user
        end.to change { User.where(user_type: bot_type).count }.by(1)
      end

      it 'creates organization_user_detail with non-conflicting username' do
        expect(bot_user.organization_user_details.count).to eq(1)

        detail = bot_user.organization_user_details.first
        expect(detail.username).not_to eq(user.username)
      end

      context 'when user belongs to another organization' do
        let!(:user) { create(:user, :with_namespace, username: bot_username, in_organization: first_organization) }

        it 'creates a non-conflicting global username and simple per-org username' do
          expect do
            bot_user
          end.to change { User.where(user_type: bot_type).count }.by(1)

          expect(bot_user.username).not_to eq(user.username)

          expect(bot_user.organization_user_details.count).to eq(1)

          detail = bot_user.organization_user_details.first
          expect(detail.username).to eq(username)
        end
      end
    end

    context 'when a regular user exists with the bot user email' do
      it 'creates a user with a non-conflicting email' do
        create(:user, email: email)

        expect do
          bot_user
        end.to change { User.where(user_type: bot_type).count }.by(1)
      end
    end

    context 'when a group namespace exists with path that is equal to the bot username' do
      let!(:group) { create(:group, path: bot_username) }

      it 'creates a user with a non-conflicting username' do
        expect do
          bot_user
        end.to change { User.where(user_type: bot_type).count }.by(1)
      end

      it 'creates organization_user_detail with non-conflicting username' do
        expect(bot_user.organization_user_details.count).to eq(1)

        detail = bot_user.organization_user_details.first
        expect(detail.username).not_to eq(group.path)
      end

      context 'when the group namespace is in another organization' do
        let!(:group) { create(:group, path: bot_username, organization: first_organization) }

        it 'creates a non-conflicting global username and simple per-org username' do
          expect do
            bot_user
          end.to change { User.where(user_type: bot_type).count }.by(1)

          expect(bot_user.username).not_to eq(bot_username)

          expect(bot_user.organization_user_details.count).to eq(1)

          detail = bot_user.organization_user_details.first
          expect(detail.username).to eq(username)
        end
      end
    end

    context 'when a domain allowlist is in place' do
      before do
        stub_application_setting(domain_allowlist: ['gitlab.com'])
      end

      it 'creates the bot user' do
        expect do
          bot_user
        end.to change { User.where(user_type: bot_type).count }.by(1)
      end
    end

    context 'when no organization is passed' do
      subject(:bot_user) { described_class.public_send(bot_type) }

      it 'sets username without suffix' do
        expect(bot_user.username).to eq(username)
      end

      it 'sets display name without suffix' do
        expect(bot_user.name).not_to include(organization.name)
      end
    end

    context 'when organization_users_internal FF is disabled' do
      before do
        stub_feature_flags(organization_users_internal: false)
      end

      it 'assigns the default organization to the created user' do
        expect(bot_user.organizations).to eq([first_organization])
      end

      it 'does not create a new user if one already exists for the first organization' do
        described_class.for_organization(first_organization).public_send(bot_type)

        expect do
          described_class.for_organization(organization).public_send(bot_type)
        end.not_to change { User.count }
      end

      it 'creates a user with no username or display name suffix' do
        expect(bot_user.username).to include(username)
        expect(bot_user.username).not_to include(organization.path)
        expect(bot_user.name).not_to include("(#{organization.name})")
      end

      it 'does not create an organization_user_detail' do
        expect(bot_user.organization_user_details).to be_empty
      end
    end
  end

  shared_examples 'bot user avatars' do |bot_type, avatar_filename|
    it 'sets the custom avatar for the created bot' do
      bot_user = described_class.for_organization(organization).public_send(bot_type)

      expect(bot_user.avatar.url).to be_present
      expect(bot_user.avatar.filename).to eq(avatar_filename)
    end
  end

  it_behaves_like 'bot users', :alert_bot, 'alert-bot', 'alert@example.com'
  it_behaves_like 'bot users', :support_bot, 'support-bot', 'support@example.com'
  it_behaves_like 'bot users', :migration_bot, 'migration-bot', 'noreply+gitlab-migration-bot@example.com'
  it_behaves_like 'bot users', :security_bot, 'GitLab-Security-Bot', 'security-bot@example.com'
  it_behaves_like 'bot users', :ghost, 'ghost', 'ghost@example.com'
  it_behaves_like 'bot users', :automation_bot, 'automation-bot', 'automation@example.com'
  it_behaves_like 'bot users', :llm_bot, 'GitLab-Llm-Bot', 'llm-bot@example.com'
  it_behaves_like 'bot users', :duo_code_review_bot, 'GitLabDuo', 'gitlab-duo@example.com'
  it_behaves_like 'bot users', :admin_bot, 'GitLab-Admin-Bot', 'admin-bot@example.com'

  it_behaves_like 'bot user avatars', :alert_bot, 'alert-bot.png'
  it_behaves_like 'bot user avatars', :support_bot, 'support-bot.png'
  it_behaves_like 'bot user avatars', :security_bot, 'security-bot.png'
  it_behaves_like 'bot user avatars', :automation_bot, 'support-bot.png'
  it_behaves_like 'bot user avatars', :llm_bot, 'support-bot.png'
  it_behaves_like 'bot user avatars', :duo_code_review_bot, 'duo-bot.png'
  it_behaves_like 'bot user avatars', :admin_bot, 'admin-bot.png'

  context 'when bot is the support_bot' do
    subject { described_class.for_organization(organization).support_bot }

    it { is_expected.to be_confirmed }
  end

  context 'when bot is the admin bot' do
    subject { described_class.for_organization(organization).admin_bot }

    it { is_expected.to be_admin }
    it { is_expected.to be_confirmed }
  end

  describe '.support_bot_id' do
    context 'when organization is not used' do
      before do
        # Ensure support bot user is created and memoization uses the same id
        # See https://gitlab.com/gitlab-org/gitlab/-/issues/509629
        described_class.clear_memoization(:support_bot_id)
        described_class.support_bot_id
      end

      subject(:support_bot_id) { described_class.support_bot_id }

      it "does not call instance support_bot_id method" do
        expect_next_instance_of(described_class) do |instance|
          expect(instance).not_to receive(:support_bot_id)
        end

        expect(support_bot_id).to eq(described_class.support_bot.id)
      end
    end

    context 'when organization is used' do
      subject { described_class.for_organization(organization).support_bot_id }

      it { is_expected.to eq(described_class.for_organization(organization).support_bot.id) }
    end
  end

  context 'when organization is not used' do
    it 'creates user in first organization' do
      bot = described_class.support_bot

      expect(bot.organizations).to eq([first_organization])
      expect(bot.namespace.organization).to eq(first_organization)
    end
  end
end
