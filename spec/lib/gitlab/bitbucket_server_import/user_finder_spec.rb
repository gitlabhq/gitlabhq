# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::BitbucketServerImport::UserFinder, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:user) { create(:user) }

  let_it_be_with_reload(:project) do
    create(:project, :repository, :bitbucket_server_import, :import_user_mapping_enabled)
  end

  let(:source_user) { build_stubbed(:import_source_user, :completed) }
  let(:user_representation) do
    {
      username: user.username,
      display_name: user.name
    }
  end

  subject(:user_finder) { described_class.new(project) }

  describe '#author_id' do
    before do
      allow_next_instance_of(Gitlab::Import::SourceUserMapper) do |isum|
        allow(isum).to receive(:find_or_create_source_user).and_return(source_user)
      end
    end

    it 'returns the mapped user' do
      expect(
        user_finder.author_id(user_representation)
      ).to eq(source_user.mapped_user.id)
    end
  end

  describe '#uid' do
    before do
      allow_next_instance_of(Gitlab::Import::SourceUserMapper) do |isum|
        allow(isum).to receive(:find_or_create_source_user).and_return(source_user)
      end
    end

    it 'takes a user data hash and finds the mapped user ID' do
      user_id = user_finder.uid(user_representation)

      expect(user_id).to eq(source_user.mapped_user.id)
    end

    it 'returns nil when username is nil' do
      user_representation[:username] = nil

      user_id = user_finder.uid(user_representation)

      expect(user_id).to be_nil
    end
  end

  context 'when user contribution mapping is disabled' do
    before do
      project.build_or_assign_import_data(data: { user_contribution_mapping_enabled: false }).save!
    end

    describe '#find_user_id' do
      context 'when user cannot be found' do
        it 'caches and returns nil' do
          expect(User).to receive(:find_by_any_email).once.and_call_original

          2.times do
            user_id = user_finder.find_user_id(by: :email, value: 'nobody@example.com')

            expect(user_id).to be_nil
          end
        end
      end

      context 'when user can be found' do
        it 'caches and returns the user ID by email' do
          expect(User).to receive(:find_by_any_email).once.and_call_original

          2.times do
            user_id = user_finder.find_user_id(by: :email, value: user.email)

            expect(user_id).to eq(user.id)
          end
        end
      end
    end

    describe '#author_id' do
      it 'calls uid method' do
        object = { author_username: user.username }

        expect(user_finder).to receive(:uid).with(object).and_return(10)
        expect(user_finder.author_id(object)).to eq(10)
      end

      context 'when corresponding user does not exist' do
        before do
          project.update!(creator_id: 123)
        end

        it 'falls back to project creator_id' do
          object = { author_email: 'unknown' }

          expect(user_finder.author_id(object)).to eq(123)
        end
      end
    end

    describe '#uid' do
      context 'when provided object is a Hash' do
        it 'maps to an existing user with the same email' do
          object = { author_email: user.email }

          expect(user_finder.uid(object)).to eq(user.id)
        end
      end

      context 'when provided object is a representation object' do
        it 'maps to an existing user with the same email' do
          object = instance_double(BitbucketServer::Representation::Comment, author_email: user.email)

          expect(user_finder.uid(object)).to eq(user.id)
        end
      end

      context 'when corresponding user does not exist' do
        it 'returns nil' do
          object = { author_email: 'unknown' }

          expect(user_finder.uid(object)).to be_nil
        end
      end
    end
  end
end
