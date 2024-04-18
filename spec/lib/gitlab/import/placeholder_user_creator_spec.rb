# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::PlaceholderUserCreator, feature_category: :importers do
  describe '#execute' do
    let(:import_type) { 'github' }
    let(:source_hostname) { 'github.com' }
    let(:source_name) { 'Pry Contributor' }
    let(:source_username) { 'a_pry_contributor' }

    subject(:service) do
      described_class.new(
        import_type: import_type,
        source_hostname: source_hostname,
        source_name: source_name,
        source_username: source_username
      )
    end

    it 'creates one new placeholder user with a unique email and username' do
      expect { service.execute }.to change { User.where(user_type: :placeholder).count }.from(0).to(1)

      new_placeholder_user = User.where(user_type: :placeholder).last

      expect(new_placeholder_user.name).to eq("Placeholder #{source_name}")
      expect(new_placeholder_user.username).to match(/^#{source_username}_placeholder_user_\d+$/)
      expect(new_placeholder_user.email).to match(/^#{source_username}_placeholder_user_\d+@#{Settings.gitlab.host}$/)
    end

    context 'when there are non-unique usernames on the same import source' do
      it 'creates two unique users with different usernames and emails' do
        placeholder_user1 = service.execute
        placeholder_user2 = service.execute

        expect(placeholder_user1.username).not_to eq(placeholder_user2.username)
        expect(placeholder_user1.email).not_to eq(placeholder_user2.email)
      end
    end

    context 'and the incoming source_user attributes are invalid' do
      context 'when source_name is nil' do
        let(:source_name) { nil }

        it 'assigns a default name' do
          placeholder_user = service.execute

          expect(placeholder_user.name).to eq("Placeholder #{import_type} Source User")
        end
      end

      context 'when source_username is nil' do
        let(:source_username) { nil }

        it 'assigns a default username' do
          placeholder_user = service.execute

          expect(placeholder_user.username).to match(/^#{import_type}_source_username_placeholder_user_\d+$/)
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
