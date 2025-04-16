# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Tasks::Gitlab::Backup, feature_category: :backup_restore do
  subject(:backup) { described_class }

  describe '.reset_pool_repositories!' do
    let(:pool_result) { ::Backup::Restore::PoolRepositories::Result }
    let(:mock_scheduled) { pool_result.new(disk_path: 'aa/bb/repo1.git', status: :scheduled, error_message: nil) }
    let(:mock_skipped) { pool_result.new(disk_path: 'cc/dd/repo2.git', status: :skipped, error_message: nil) }
    let(:mock_failed) { pool_result.new(disk_path: 'ee/ff/repo3.git', status: :failed, error_message: 'Error message') }

    it 'delegates to ::Backup::Restore::PoolRepositories.reinitialize_pools!' do
      expect(::Backup::Restore::PoolRepositories).to receive(:reinitialize_pools!)

      backup.reset_pool_repositories!
    end

    it 'prints returned data as json' do
      expect(::Backup::Restore::PoolRepositories).to receive(:reinitialize_pools!)
                                                       .and_yield(mock_scheduled)
                                                       .and_yield(mock_skipped)
                                                       .and_yield(mock_failed)

      expect { backup.reset_pool_repositories! }.to output(<<~OUTPUT).to_stdout
        {"disk_path":"aa/bb/repo1.git","status":"scheduled","error_message":null}
        {"disk_path":"cc/dd/repo2.git","status":"skipped","error_message":null}
        {"disk_path":"ee/ff/repo3.git","status":"failed","error_message":"Error message"}
      OUTPUT
    end
  end
end
