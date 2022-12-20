# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ::Gitlab::RepositoryArchiveRateLimiter do
  let(:described_class) do
    Class.new do
      include ::Gitlab::RepositoryArchiveRateLimiter

      def check_rate_limit!(**args); end
    end
  end

  describe "#check_archive_rate_limit!" do
    let(:project) { instance_double('Project') }
    let(:current_user) { instance_double('User') }
    let(:check) { subject.check_archive_rate_limit!(current_user, project) }

    context 'when archive_rate_limit feature flag is disabled' do
      before do
        stub_feature_flags(archive_rate_limit: false)
      end

      it 'does not check rate limit' do
        expect(subject).not_to receive(:check_rate_limit!)

        expect(check).to eq nil
      end
    end

    context 'when archive_rate_limit feature flag is enabled' do
      before do
        stub_feature_flags(archive_rate_limit: true)
      end

      context 'when current user exists' do
        it 'checks for project_repositories_archive rate limiting with default threshold' do
          expect(subject).to receive(:check_rate_limit!)
                               .with(:project_repositories_archive, scope: [project, current_user], threshold: nil)
          check
        end
      end

      context 'when current user does not exist' do
        let(:current_user) { nil }

        it 'checks for project_repositories_archive rate limiting with threshold 100' do
          expect(subject).to receive(:check_rate_limit!)
                               .with(:project_repositories_archive, scope: [project, current_user], threshold: 100)
          check
        end
      end
    end
  end
end
