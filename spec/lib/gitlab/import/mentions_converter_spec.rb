# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::MentionsConverter, :clean_gitlab_redis_shared_state, feature_category: :importers do
  let_it_be(:project) { create(:project) }
  let(:project_id) { project.id }
  let(:importer) { 'bitbucket_server' }
  let(:text) { 'text without @ mentions' }
  let(:source_user_cache_prefix) { "bitbucket_server/project/#{project_id}/source" }

  subject(:converted_text) { described_class.new(importer, project).convert(text) }

  describe '#convert' do
    context 'when the text has no mentions' do
      it 'does not change the text' do
        expect(converted_text).to eq(text)
      end
    end

    context 'when the text has a mention' do
      let(:text) { 'mentioning @john' }
      let(:cache_key) { '' }

      context 'and the mention maps to a user record' do
        let_it_be(:user) { create(:user, username: 'johndoe', email: 'john@example.com') }
        let(:cache_key) { "#{source_user_cache_prefix}/john" }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key, { value: 'john@example.com', type: :email }.to_json)
        end

        it "replaces the mention with the user's username" do
          expect(converted_text).to eq('mentioning @johndoe')
        end
      end

      context 'and the mention maps to cached text' do
        let_it_be(:user) { create(:user, username: 'John Doe', email: 'jane@example.com') }
        let(:cache_key) { "#{source_user_cache_prefix}/john" }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key, { value: 'John Doe', type: :name }.to_json)
        end

        it 'puts the name mention in backticks' do
          expect(converted_text).to eq('mentioning `@John Doe`')
        end
      end

      context 'and the mention does not map to anything' do
        let_it_be(:user) { create(:user, username: 'jane', email: 'jane@example.com') }
        let(:cache_key) { "#{source_user_cache_prefix}/jane" }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key, { value: 'jane@example.com', type: :email }.to_json)
        end

        it 'puts the mention in backticks' do
          expect(converted_text).to eq('mentioning `@john`')
        end
      end

      context 'when no user data is cached' do
        it 'puts the mention in backticks' do
          expect(converted_text).to eq('mentioning `@john`')
        end
      end

      context 'when the mention has emails' do
        let(:text) { "@john's email is john@gmail.com and @jane's email is info@jane." }

        it 'does not alter the emails' do
          expect(converted_text).to eq("`@john`'s email is john@gmail.com and `@jane`'s email is info@jane.")
        end
      end
    end

    context 'when the text has multiple mentions that map to users' do
      let(:text) { "@john, @jane-doe and @johndoe123 with \n@john again on a newline" }

      context 'if none of the mentions have matching users' do
        it 'puts every mention in backticks' do
          expect(converted_text).to eq("`@john`, `@jane-doe` and `@johndoe123` with \n`@john` again on a newline")
        end
      end

      context 'if multiple GitLab-like mentions have matching users' do
        let_it_be(:user_1) { create(:user, username: 'johndoe', email: 'john@example.com') }
        let_it_be(:user_2) { create(:user, username: 'jane-gitlab', email: 'jane@example.com') }
        let(:cache_key_1) { "#{source_user_cache_prefix}/john" }
        let(:cache_key_2) { "#{source_user_cache_prefix}/jane-doe" }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key_1, { value: 'john@example.com', type: :email }.to_json)
          ::Gitlab::Cache::Import::Caching.write(cache_key_2, { value: 'jane@example.com', type: :email }.to_json)
        end

        it 'replaces all mentions with the username and puts rest of mentions in backticks' do
          expect(converted_text).to eq("@johndoe, @jane-gitlab and `@johndoe123` with \n@johndoe again on a newline")
        end
      end
    end

    context 'when the text has multiple Bitbucket mentions that map to replacement names for readability' do
      let(:text) { "@{1111:11-11}, @{2222:22-22} and @{3333:33-33} with \n@{1111:11-11} again on a newline" }

      context 'if none of the mentions map to user text' do
        it 'puts every mention in backticks' do
          expect(converted_text).to eq(
            "`@{1111:11-11}`, `@{2222:22-22}` and `@{3333:33-33}` with \n`@{1111:11-11}` again on a newline"
          )
        end
      end

      context 'if multiple mentions map to user text' do
        let(:cache_key_1) { "#{source_user_cache_prefix}/{1111:11-11}" }
        let(:cache_key_2) { "#{source_user_cache_prefix}/{2222:22-22}" }

        before do
          ::Gitlab::Cache::Import::Caching.write(cache_key_1, { value: 'John Doe', type: :name }.to_json)
          ::Gitlab::Cache::Import::Caching.write(cache_key_2, { value: 'Jane Doe', type: :name }.to_json)
        end

        it 'replaces all mentions with the name mention and puts all mentions in backticks' do
          expect(converted_text).to eq(
            "`@John Doe`, `@Jane Doe` and `@{3333:33-33}` with \n`@John Doe` again on a newline"
          )
        end
      end
    end

    context 'when the text has mentions with special characters' do
      let_it_be(:user) { create(:user, username: 'johndoe', email: 'john@example.com') }
      let(:cache_key_gl) { "#{source_user_cache_prefix}/john_DOE-123" }
      let(:cache_key_bb) { "#{source_user_cache_prefix}/{1111:11-11}" }
      let(:text) { '@john_DOE-123 is a GitLab-like mention, @{1111:11-11} is a Bitbucket mention' }

      before do
        ::Gitlab::Cache::Import::Caching.write(cache_key_gl, { value: 'john@example.com', type: :email }.to_json)
        ::Gitlab::Cache::Import::Caching.write(cache_key_bb, { value: 'John Doe', type: :name }.to_json)
      end

      it 'only replaces the mentions that fit GitLab\'s user reference pattern and mentions wrapped in @{}' do
        expect(converted_text).to eq('@johndoe is a GitLab-like mention, `@John Doe` is a Bitbucket mention')
      end
    end
  end
end
