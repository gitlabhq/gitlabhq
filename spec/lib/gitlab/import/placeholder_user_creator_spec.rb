# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::PlaceholderUserCreator, feature_category: :importers do
  let_it_be(:namespace) { create(:namespace) }

  let(:import_type) { 'github' }
  let(:source_hostname) { 'github.com' }
  let(:source_name) { 'Pry Contributor' }
  let(:source_username) { 'a_pry_contributor' }
  let(:source_user_identifier) { '1' }

  let(:source_user) do
    build(:import_source_user,
      import_type: import_type,
      source_hostname: source_hostname,
      source_name: source_name,
      source_username: source_username,
      source_user_identifier: source_user_identifier,
      namespace: namespace
    )
  end

  subject(:service) { described_class.new(source_user) }

  describe '#execute' do
    it 'creates one new placeholder user with a unique email and username' do
      expect { service.execute }.to change { User.where(user_type: :placeholder).count }.from(0).to(1)

      new_placeholder_user = User.where(user_type: :placeholder).last

      expect(new_placeholder_user.name).to eq("Placeholder #{source_name}")
      expect(new_placeholder_user.username).to match(/^aprycontributor_placeholder_user_\d+$/)
      expect(new_placeholder_user.email).to match(/^#{import_type}_\h+_\d+@#{Settings.gitlab.host}$/)
      expect(new_placeholder_user.namespace.organization).to eq(namespace.organization)
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
        allow(Zlib).to receive(:crc32).and_return(123)

        existing_user = create(:user, email: 'github_7b_1@localhost')
        existing_user.emails.create!(email: 'github_7b_2@localhost')

        placeholder_user = service.execute

        expect(placeholder_user.email).to eq('github_7b_3@localhost')
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
          expected_match = /^#{import_type}_\h+_placeholder_user_\d+$/

          placeholder_user = service.execute

          expect(placeholder_user.username).to match(expected_match)
        end
      end

      context 'when the source_username contains invalid characters' do
        using RSpec::Parameterized::TableSyntax

        where(:input_username, :expected_output) do
          '.asdf'     | /^asdf_placeholder_user_1$/
          'asdf^ghjk' | /^asdfghjk_placeholder_user_1$/
          '.'         | /^#{import_type}_\h+_placeholder_user_1$/
        end

        with_them do
          let(:source_username) { input_username }

          it do
            placeholder_user = service.execute

            expect(placeholder_user.username).to match(expected_output)
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

  describe '#placeholder_name' do
    it 'prepends Placeholder to source_name' do
      expect(service.placeholder_name).to eq("Placeholder #{source_name}")
    end

    context 'when source_name is nil' do
      let(:source_name) { nil }

      it 'assigns a default name' do
        expect(service.placeholder_name).to eq("Placeholder #{import_type} Source User")
      end
    end
  end

  describe '#placeholder_username' do
    it 'returns an unique placeholder username' do
      expect(service.placeholder_username).to match(/^aprycontributor_placeholder_user_\d+$/)
    end

    context 'when source_username is nil' do
      let(:source_username) { nil }

      it 'assigns a default username' do
        expected_match = /^#{import_type}_\h+_placeholder_user_\d+$/

        expect(service.placeholder_username).to match(expected_match)
      end
    end
  end

  describe '.placeholder_email_pattern' do
    subject(:placeholder_email_pattern) { described_class.placeholder_email_pattern }

    ::Import::HasImportSource::IMPORT_SOURCES.except(:none).each_key do |import_type|
      it "matches the emails created for placeholder users imported from #{import_type}" do
        import_source_user = create(:import_source_user, import_type: import_type)
        placeholder_user = described_class.new(import_source_user).execute

        expect(placeholder_email_pattern === placeholder_user.email).to eq(true)
      end
    end

    it 'does not match emails without an import source' do
      email = 'email_12e4ab78_1@gitlab.com'

      expect(placeholder_email_pattern === email).to eq(false)
    end

    it 'does not match emails with domains other than the host' do
      email = "github_12e4ab78_2@not#{Settings.gitlab.host}"

      expect(placeholder_email_pattern === email).to eq(false)
    end
  end
end
