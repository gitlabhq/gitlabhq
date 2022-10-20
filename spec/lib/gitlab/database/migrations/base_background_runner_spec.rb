# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BaseBackgroundRunner, :freeze_time do
  let(:connection) { ApplicationRecord.connection }

  let(:result_dir) { Dir.mktmpdir }

  after do
    FileUtils.rm_rf(result_dir)
  end

  context 'subclassing' do
    subject { described_class.new(result_dir: result_dir, connection: connection) }

    it 'requires that jobs_by_migration_name be implemented' do
      expect { subject.jobs_by_migration_name }.to raise_error(NotImplementedError)
    end

    it 'requires that run_job be implemented' do
      expect { subject.run_job(nil) }.to raise_error(NotImplementedError)
    end
  end
end
