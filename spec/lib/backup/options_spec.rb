# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Backup::Options, feature_category: :backup_restore do
  include StubENV

  subject(:options) { described_class.new }

  context 'with accessors' do
    describe 'backup_id' do
      it { is_expected.to respond_to :backup_id }
      it { is_expected.to respond_to :backup_id= }
    end

    describe 'previous_backup' do
      it { is_expected.to respond_to :previous_backup }
      it { is_expected.to respond_to :previous_backup= }
    end

    describe 'incremental' do
      it { is_expected.to respond_to :incremental }
      it { is_expected.to respond_to :incremental= }
    end

    describe 'force' do
      it { is_expected.to respond_to :force }
      it { is_expected.to respond_to :force= }
    end

    describe 'strategy' do
      it { is_expected.to respond_to :strategy }
      it { is_expected.to respond_to :strategy= }
    end

    describe 'skippable_tasks' do
      it { is_expected.to respond_to :skippable_tasks }
      it { is_expected.to respond_to :skippable_tasks= }
    end

    describe 'skippable_operations' do
      it { is_expected.to respond_to :skippable_operations }
      it { is_expected.to respond_to :skippable_operations= }
    end

    describe 'max_parallelism' do
      it { is_expected.to respond_to :max_parallelism }
      it { is_expected.to respond_to :max_parallelism= }
    end

    describe 'max_storage_parallelism' do
      it { is_expected.to respond_to :max_storage_parallelism }
      it { is_expected.to respond_to :max_storage_parallelism= }
    end

    describe 'repositories_storages' do
      it { is_expected.to respond_to :repositories_storages }
      it { is_expected.to respond_to :repositories_storages= }
    end

    describe 'repositories_paths' do
      it { is_expected.to respond_to :repositories_paths }
      it { is_expected.to respond_to :repositories_paths= }
    end

    describe 'skip_repositories_paths' do
      it { is_expected.to respond_to :skip_repositories_paths }
      it { is_expected.to respond_to :skip_repositories_paths= }
    end

    describe 'repositories_server_side_backup' do
      it { is_expected.to respond_to :repositories_server_side_backup }
      it { is_expected.to respond_to :repositories_server_side_backup= }
    end

    describe 'remote_directory' do
      it { is_expected.to respond_to :remote_directory }
      it { is_expected.to respond_to :remote_directory= }
    end

    describe 'compression_options' do
      it { is_expected.to respond_to :compression_options }
      it { is_expected.to respond_to :compression_options= }
    end

    describe 'gzip_rsyncable' do
      it { is_expected.to respond_to :gzip_rsyncable }
      it { is_expected.to respond_to :gzip_rsyncable= }
    end
  end

  describe '#initialize' do
    it 'can be initialized without providing any parameter' do
      expect { described_class.new }.not_to raise_exception
    end

    it 'can be initialized with all valid parameters' do
      expect { FactoryBot.build(:backup_options, :all) }.not_to raise_exception
    end
  end

  describe '#extract_from_env!' do
    it 'extracts BACKUP env' do
      env_value = '11493107454_2018_04_25_10.6.4-ce'
      stub_env('BACKUP' => env_value)

      expect { options.extract_from_env! }.to change { options.backup_id }.to(env_value)
    end

    it 'extracts PREVIOUS_BACKUP env' do
      env_value = '11493107454_2018_04_25_10.6.4-ce'
      stub_env('PREVIOUS_BACKUP' => env_value)

      expect { options.extract_from_env! }.to change { options.previous_backup }.to(env_value)
    end

    it 'extracts INCREMENTAL env' do
      stub_env('INCREMENTAL' => 'yes')

      expect { options.extract_from_env! }.to change { options.incremental }.to(true)
    end

    it 'extracts FORCE env' do
      stub_env('FORCE' => 'yes')

      expect { options.extract_from_env! }.to change { options.force }.to(true)
    end

    it 'extracts STRATEGY env' do
      stub_env('STRATEGY' => 'copy')

      expect { options.extract_from_env! }.to change { options.strategy }.to(::Backup::Options::Strategy::COPY)
    end

    it 'extracts GITLAB_BACKUP_MAX_CONCURRENCY env' do
      stub_env('GITLAB_BACKUP_MAX_CONCURRENCY' => '8')

      expect { options.extract_from_env! }.to change { options.max_parallelism }.to(8)
    end

    it 'extracts GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY env' do
      stub_env('GITLAB_BACKUP_MAX_STORAGE_CONCURRENCY' => '3')

      expect { options.extract_from_env! }.to change { options.max_storage_parallelism }.to(3)
    end

    it 'extracts DIRECTORY env' do
      directory = 'daily'
      stub_env('DIRECTORY' => directory)

      expect { options.extract_from_env! }.to change { options.remote_directory }.to(directory)
    end

    it 'extracts REPOSITORIES_SERVER_SIDE env' do
      stub_env('REPOSITORIES_SERVER_SIDE' => 'yes')

      expect { options.extract_from_env! }.to change { options.repositories_server_side_backup }.to(true)
    end

    it 'extracts REPOSITORIES_STORAGES env' do
      stub_env('REPOSITORIES_STORAGES' => 'storage1,storage2')

      expect { options.extract_from_env! }.to change { options.repositories_storages }.to(%w[storage1 storage2])
    end

    it 'extracts REPOSITORIES_PATHS env' do
      stub_env('REPOSITORIES_PATHS' => 'group-a,group-b/project-c')

      expect { options.extract_from_env! }.to change { options.repositories_paths }.to(%w[group-a group-b/project-c])
    end

    it 'extracts SKIP_REPOSITORIES_PATHS env' do
      stub_env('SKIP_REPOSITORIES_PATHS' => 'group-a/project-d,group-a/project-e')

      expect { options.extract_from_env! }.to change {
                                                options.skip_repositories_paths
                                              }.to(%w[group-a/project-d group-a/project-e])
    end

    it 'extracts COMPRESS_CMD env' do
      cmd = 'pigz --compress --stdout --fast --processes=4'
      stub_env('COMPRESS_CMD' => cmd)

      expect { options.extract_from_env! }.to change { options.compression_options.compression_cmd }.to(cmd)
    end

    it 'extracts DECOMPRESS_CMD env' do
      cmd = 'pigz --decompress --stdout"'
      stub_env('DECOMPRESS_CMD' => cmd)

      expect { options.extract_from_env! }.to change { options.compression_options.decompression_cmd }.to(cmd)
    end

    it 'extracts GZIP_RSYNCABLE env' do
      stub_env('GZIP_RSYNCABLE' => 'yes')

      expect { options.extract_from_env! }.to change { options.gzip_rsyncable }.to(true)
    end

    it 'delegates to extract_skippables! when SKIP env is present' do
      stub_env('SKIP' => 'db')
      expect(options).to receive(:extract_skippables!)

      options.extract_from_env!
    end

    it 'does not call extract_skippables! when SKIP env is missing' do
      stub_env('SKIP' => nil)
      expect(options).not_to receive(:extract_skippables!)

      options.extract_from_env!
    end
  end

  describe '#extract_skippables!' do
    let(:skippable_field) do
      'tar,remote,db,uploads,builds,artifacts,lfs,terraform_state,registry,pages,repositories,packages,ci_secure_files'
    end

    context 'for skippable operations' do
      it 'parses skippable tar input' do
        expect do
          options.extract_skippables!(skippable_field)
        end.to change { options.skippable_operations.archive }.to(true)
      end

      it 'parses skippable remote input' do
        expect do
          options.extract_skippables!(skippable_field)
        end.to change { options.skippable_operations.remote_storage }.to(true)
      end
    end

    context 'for skippable tasks' do
      it 'parses skippable db input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.db }.to(true)
      end

      it 'parses skippable uploads input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.uploads }.to(true)
      end

      it 'parses skippable builds input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.builds }.to(true)
      end

      it 'parses skippable artifacts input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.artifacts }.to(true)
      end

      it 'parses skippable lfs input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.lfs }.to(true)
      end

      it 'parses skippable terraform_state input' do
        expect do
          options.extract_skippables!(skippable_field)
        end.to change { options.skippable_tasks.terraform_state }.to(true)
      end

      it 'parses skippable registry input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.registry }.to(true)
      end

      it 'parses skippable pages input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.pages }.to(true)
      end

      it 'parses skippable repositories input' do
        expect do
          options.extract_skippables!(skippable_field)
        end.to change { options.skippable_tasks.repositories }.to(true)
      end

      it 'parses skippable packages input' do
        expect { options.extract_skippables!(skippable_field) }.to change { options.skippable_tasks.packages }.to(true)
      end

      it 'parses skippable ci_secure_files input' do
        expect do
          options.extract_skippables!(skippable_field)
        end.to change { options.skippable_tasks.ci_secure_files }.to(true)
      end
    end
  end

  describe '#skip_task?' do
    tasks = %w[db uploads builds artifacts lfs terraform_state registry pages repositories packages ci_secure_files]

    tasks.each do |task_name|
      it "returns true when task #{task_name} is skipped" do
        options.skippable_tasks[task_name] = true

        expect(options.skip_task?(task_name)).to be(true)
      end

      it "returns false when task #{task_name} has default skip behavior" do
        expect(options.skip_task?(task_name)).to be(false)
      end
    end
  end
end
