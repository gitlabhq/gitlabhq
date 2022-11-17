# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Backup::DatabaseBackupError do
  let(:config) do
    {
      host: 'localhost',
      port: 5432,
      database: 'gitlabhq_test'
    }
  end

  let(:db_file_name) { File.join(Gitlab.config.backup.path, 'db', 'database.sql.gz') }

  subject { described_class.new(config, db_file_name) }

  it { is_expected.to respond_to :config }
  it { is_expected.to respond_to :db_file_name }

  it 'expects exception message to include database file' do
    expect(subject.message).to include(db_file_name.to_s)
  end

  it 'expects exception message to include database paths being back-up' do
    expect(subject.message).to include(config[:host].to_s)
    expect(subject.message).to include(config[:port].to_s)
    expect(subject.message).to include(config[:database].to_s)
  end
end
