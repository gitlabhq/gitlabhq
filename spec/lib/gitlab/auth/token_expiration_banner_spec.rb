# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Auth::TokenExpirationBanner, feature_category: :system_access do
  describe '.show_token_expiration_banner?' do
    subject(:show_token_expiration_banner) { described_class.show_token_expiration_banner? }

    let(:gitlab_version) { Gitlab::VersionInfo.new(16, 0) }
    let(:model_class) { Gitlab::Database::BackgroundMigration::BatchedMigration }

    # this method is meant to be memoized on app boot and not changed
    # for specs, we need to reset it each time
    before do
      described_class.instance_variable_set(:@show_token_expiration_banner, nil)
      allow(Gitlab).to receive(:version_info).twice.and_return(gitlab_version)
    end

    it { is_expected.to be(false) }

    it 'memoizes results' do
      expect(described_class.show_token_expiration_banner?).to be(false)
      expect(model_class).not_to receive(:where)

      # Second call shouldn't trigger database query
      expect(show_token_expiration_banner).to be(false)
    end

    context 'when the batched migration is present in the db' do
      before do
        create(
          :batched_background_migration,
          job_class_name: 'CleanupPersonalAccessTokensWithNilExpiresAt'
        )
      end

      it { is_expected.to be(true) }

      it 'memoizes results' do
        expect(described_class.show_token_expiration_banner?).to be(true)
        expect(model_class).not_to receive(:where)

        # Second call shouldn't trigger database query
        expect(show_token_expiration_banner).to be(true)
      end

      context 'when banner is disabled by env var' do
        before do
          stub_env('GITLAB_DISABLE_TOKEN_EXPIRATION_BANNER', '1')
        end

        it { is_expected.to be(false) }
      end

      context 'when not in affected version range' do
        let(:gitlab_version) { Gitlab::VersionInfo.new(17, 2) }

        it { is_expected.to be(false) }
      end
    end
  end
end
