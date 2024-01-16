# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Import::MentionsConverter, :clean_gitlab_redis_cache, feature_category: :importers do
  let(:project_id) { 12 }
  let(:importer) { 'bitbucket_server' }
  let(:text) { 'text without @ mentions' }
  let(:source_user_cache_prefix) { "bitbucket_server/project/#{project_id}/source/username" }

  subject(:converted_text) { described_class.new(importer, project_id).convert(text) }

  describe '#convert' do
    context 'when the text has no mentions' do
      it 'does not change the text' do
        expect(converted_text).to eq(text)
      end
    end

    context 'when the text has a mention' do
      let(:text) { 'mentioning @john' }

      context 'when the mention has matching cached email' do
        before do
          ::Gitlab::Cache::Import::Caching.write("#{source_user_cache_prefix}/john", 'john@example.com')
        end

        context 'when a user with the email does not exist on gitlab' do
          it 'puts the mention in backticks' do
            expect(converted_text).to eq('mentioning `@john`')
          end
        end

        context 'when a user with the same email exists on gitlab' do
          let_it_be(:user) { create(:user, username: 'johndoe', email: 'john@example.com') }

          it "replaces the mention with the user's username" do
            expect(converted_text).to eq('mentioning @johndoe')
          end
        end

        context 'when a user with the same username but not email exists on gitlab' do
          let_it_be(:user) { create(:user, username: 'john') }

          it 'puts the mention in backticks' do
            expect(converted_text).to eq('mentioning `@john`')
          end
        end
      end

      context 'when there is cached email but not for the mentioned username' do
        before do
          ::Gitlab::Cache::Import::Caching.write("#{source_user_cache_prefix}/jane", 'jane@example.com')
        end

        it 'puts the mention in backticks' do
          expect(converted_text).to eq('mentioning `@john`')
        end

        context 'when a user with the same email exists on gitlab' do
          let_it_be(:user) { create(:user, username: 'jane', email: 'jane@example.com') }

          it 'puts the mention in backticks' do
            expect(converted_text).to eq('mentioning `@john`')
          end
        end
      end

      context 'when the mention has digits, underscores, uppercase and hyphens' do
        let(:text) { '@john_DOE-123' }
        let_it_be(:user) { create(:user, username: 'johndoe', email: 'john@example.com') }

        before do
          ::Gitlab::Cache::Import::Caching.write("#{source_user_cache_prefix}/john_DOE-123", 'john@example.com')
        end

        it "replaces the mention with the user's username" do
          expect(converted_text).to eq('@johndoe')
        end
      end

      context 'when the mention has emails' do
        let(:text) { "@john's email is john@gmail.com and @jane's email is info@jane." }

        it 'does not alter the emails' do
          expect(converted_text).to eq("`@john`'s email is john@gmail.com and `@jane`'s email is info@jane.")
        end
      end

      context 'when no emails are cached' do
        it 'puts the mention in backticks' do
          expect(converted_text).to eq('mentioning `@john`')
        end
      end
    end

    context 'when the text has multiple mentions' do
      let(:text) { "@john, @jane-doe and @johndoe123 with \n@john again on a newline" }

      context 'if none of the mentions have matching cached emails and users' do
        it 'puts every mention in backticks' do
          expect(converted_text).to eq("`@john`, `@jane-doe` and `@johndoe123` with \n`@john` again on a newline")
        end
      end

      context 'if one of the mentions have matching user' do
        let_it_be(:user) { create(:user, username: 'johndoe', email: 'john@example.com') }

        before do
          ::Gitlab::Cache::Import::Caching.write("#{source_user_cache_prefix}/john", 'john@example.com')
        end

        it 'replaces all mentions with the username and puts rest of mentions in backticks' do
          expect(converted_text).to eq("@johndoe, `@jane-doe` and `@johndoe123` with \n@johndoe again on a newline")
        end
      end
    end
  end
end
