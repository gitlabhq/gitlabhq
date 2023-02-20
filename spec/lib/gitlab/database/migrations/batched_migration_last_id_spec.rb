# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Migrations::BatchedMigrationLastId, feature_category: :database do
  subject(:test_sampling) { described_class.new(connection, base_dir) }

  let(:base_dir) { Pathname.new(Dir.mktmpdir) }
  let(:file_name) { 'last-batched-background-migration-id.txt' }
  let(:file_path) { base_dir.join(file_name) }
  let(:file_contents) { nil }

  where(:base_model) do
    [
      [ApplicationRecord], [Ci::ApplicationRecord]
    ]
  end

  with_them do
    let(:connection) { base_model.connection }

    after do
      FileUtils.rm_rf(file_path)
    end

    describe '#read' do
      before do
        File.write(file_path, file_contents)
      end

      context 'when the file exists and have content' do
        let(:file_contents) { 99 }

        it { expect(test_sampling.read).to eq(file_contents) }
      end

      context 'when the file exists and is blank' do
        it { expect(test_sampling.read).to be_nil }
      end

      context "when the file doesn't exists" do
        before do
          FileUtils.rm_rf(file_path)
        end

        it { expect(test_sampling.read).to be_nil }
      end
    end

    describe '#store' do
      let(:file_contents) { File.read(file_path) }
      let(:migration) do
        Gitlab::Database::SharedModel.using_connection(connection) do
          create(:batched_background_migration)
        end
      end

      it 'creates the file properly' do
        test_sampling.store

        expect(File).to exist(file_path)
      end

      it 'stores the proper id in the file' do
        migration
        test_sampling.store

        expect(file_contents).to eq(migration.id.to_s)
      end
    end
  end
end
