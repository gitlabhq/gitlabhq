# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'sidekiq' do
  describe 'enable_reliable_fetch?' do
    subject { enable_reliable_fetch? }

    context 'when gitlab_sidekiq_reliable_fetcher is enabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_reliable_fetcher: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when gitlab_sidekiq_reliable_fetcher is disabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_reliable_fetcher: false)
      end

      it { is_expected.to be_falsey }
    end
  end

  describe 'enable_semi_reliable_fetch_mode?' do
    subject { enable_semi_reliable_fetch_mode? }

    context 'when gitlab_sidekiq_enable_semi_reliable_fetcher is enabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_enable_semi_reliable_fetcher: true)
      end

      it { is_expected.to be_truthy }
    end

    context 'when gitlab_sidekiq_enable_semi_reliable_fetcher is disabled' do
      before do
        stub_feature_flags(gitlab_sidekiq_enable_semi_reliable_fetcher: false)
      end

      it { is_expected.to be_falsey }
    end
  end
end
