require 'spec_helper'

describe Gitlab::Geo::DatabaseTasks do
  let(:schema_file) { Rails.root.join('tmp', 'tests', 'geo_schema.rb').to_s }
  subject { described_class }

  before do
    stub_env('SCHEMA', schema_file) # schema will be dumped to this file
  end

  after do
    FileUtils.rm_rf(schema_file)
  end

  [:drop_current, :create_current, :migrate, :load_seed, :load_schema_current].each do |method_name|
    it "defines the missing method #{method_name}" do
      is_expected.to respond_to(method_name)
    end

    it "forwards method #{method_name} to ActiveRecord::Tasks::DatabaseTasks" do
      expect(ActiveRecord::Tasks::DatabaseTasks).to receive(method_name)

      subject.public_send(method_name)
    end
  end

  describe '.rollback' do
    context 'ENV["STEP"] not set' do
      it 'calls ActiveRecord::Migrator.rollback with step 1' do
        expect(ActiveRecord::Migrator).to receive(:rollback).with(anything, 1)

        subject.rollback
      end
    end
  end

  describe '.version' do
    it 'returns a Number' do
      expect(subject.version).to be_an(Integer)
    end
  end

  describe '.dump_schema_after_migration?' do
    it 'returns a true value' do
      expect(subject.dump_schema_after_migration?).to be_truthy
    end
  end

  describe '.pending_migrations' do
    it 'returns an array' do
      expect(subject.pending_migrations).to be_an(Array)
    end
  end

  describe described_class::Schema do
    describe '.dump' do
      it 'calls ActiveRecord::SchemaDumper.dump' do
        expect(ActiveRecord::SchemaDumper).to receive(:dump)

        subject.dump
      end
    end
  end

  describe described_class::Migrate do
    describe '.up' do
      it 'requires ENV["VERSION"] to be set' do
        stub_env('VERSION', nil)

        expect { subject.up }.to raise_error(/VERSION is required/)
      end

      it 'calls ActiveRecord::Migrator.run' do
        stub_env('VERSION', '19700101120000')
        expect(ActiveRecord::Migrator).to receive(:run).with(:up, any_args)

        subject.up
      end
    end

    describe '.down' do
      it 'requires ENV["VERSION"] to be set' do
        stub_env('VERSION', nil)

        expect { subject.down }.to raise_error(/VERSION is required/)
      end

      it 'calls ActiveRecord::Migrator.run' do
        stub_env('VERSION', '19700101120000')
        expect(ActiveRecord::Migrator).to receive(:run).with(:down, any_args)

        subject.down
      end
    end

    describe '.status' do
      it 'outputs "database: gitlabhq_geo_test"' do
        expect(ActiveRecord::SchemaMigration).to receive(:normalized_versions).and_return([])

        expect { subject.status }.to output(/database: gitlabhq_geo_test/).to_stdout
      end
    end
  end

  describe described_class::Test do
    describe '.load' do
      it 'calls ActiveRecord::Tasks::DatabaseTasks.load_schema_for' do
        expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:load_schema_for)

        subject.load
      end
    end

    describe '.purge' do
      it 'calls ActiveRecord::Tasks::DatabaseTasks.load_schema_for' do
        expect(ActiveRecord::Tasks::DatabaseTasks).to receive(:purge)

        subject.purge
      end
    end
  end
end
