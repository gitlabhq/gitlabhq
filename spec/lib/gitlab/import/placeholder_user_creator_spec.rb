# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::PlaceholderUserCreator, feature_category: :importers do
  describe '#execute' do
    let_it_be(:organization) { create(:organization) }

    let(:import_type) { 'github' }
    let(:source_hostname) { 'github.com' }
    let(:source_name) { 'Pry Contributor' }
    let(:source_username) { 'a_pry_contributor' }

    subject(:service) do
      described_class.new(
        import_type: import_type,
        source_hostname: source_hostname,
        source_name: source_name,
        source_username: source_username,
        organization: organization
      )
    end

    it 'creates one new placeholder user with a unique email and username' do
      expect { service.execute }.to change { User.where(user_type: :placeholder).count }.from(0).to(1)

      new_placeholder_user = User.where(user_type: :placeholder).last

      expect(new_placeholder_user.name).to eq("Placeholder #{source_name}")
      expect(new_placeholder_user.username).to match(/^aprycontributor_placeholder_user_\d+$/)
      expect(new_placeholder_user.email).to match(/^aprycontributor_placeholder_user_\d+@#{Settings.gitlab.host}$/)
      expect(new_placeholder_user.namespace.organization).to eq(organization)
    end

    context 'when there are non-unique usernames on the same import source' do
      it 'creates two unique users with different usernames and emails' do
        placeholder_user1 = service.execute
        placeholder_user2 = service.execute

        expect(placeholder_user1.username).not_to eq(placeholder_user2.username)
        expect(placeholder_user1.email).not_to eq(placeholder_user2.email)
      end
    end

    context 'when generating a unique email address' do
      it 'validates against all stored email addresses' do
        existing_user = create(:user, email: 'aprycontributor_placeholder_user_1@localhost')
        existing_user.emails.create!(email: 'aprycontributor_placeholder_user_2@localhost')

        placeholder_user = service.execute

        expect(placeholder_user.email).to eq('aprycontributor_placeholder_user_3@localhost')
      end
    end

    context 'when the incoming source_user attributes are invalid' do
      context 'when source_name is nil' do
        let(:source_name) { nil }

        it 'assigns a default name' do
          placeholder_user = service.execute

          expect(placeholder_user.name).to eq("Placeholder #{import_type} Source User")
        end
      end

      context 'when source_name is too long' do
        let(:source_name) { 'a' * 500 }

        it 'truncates the source name to 127 characters' do
          placeholder_user = service.execute

          expect(placeholder_user.first_name).to eq('Placeholder')
          expect(placeholder_user.last_name).to eq('a' * 127)
        end
      end

      context 'when source_username is nil' do
        let(:source_username) { nil }

        it 'assigns a default username' do
          placeholder_user = service.execute

          expect(placeholder_user.username).to match(/^#{import_type}_source_username_placeholder_user_\d+$/)
        end
      end

      context 'when the source_username contains invalid characters' do
        using RSpec::Parameterized::TableSyntax

        where(:input_username, :expected_output) do
          '.asdf'     | 'asdf_placeholder_user_1'
          'asdf^ghjk' | 'asdfghjk_placeholder_user_1'
          '.'         | 'github_source_username_placeholder_user_1'
        end

        with_them do
          let(:source_username) { input_username }

          it do
            placeholder_user = service.execute

            expect(placeholder_user.username).to eq(expected_output)
          end
        end
      end

      context 'when source_username is too long' do
        let(:source_username) { 'a' * 500 }

        it 'truncates the original username to 200 characters' do
          placeholder_user = service.execute

          expect(placeholder_user.username).to match(/^#{'a' * 200}_placeholder_user_\d+$/)
        end
      end
    end
  end
end
