# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Database config initializer' do
  subject do
    load Rails.root.join('config/initializers/database_config.rb')
  end

  around do |example|
    original_config = ActiveRecord::Base.connection_db_config

    example.run

    ActiveRecord::Base.establish_connection(original_config)
  end

  before do
    allow(Gitlab::Runtime).to receive(:max_threads).and_return(max_threads)
  end

  let(:max_threads) { 8 }

  context "no existing pool size is set" do
    before do
      stub_database_config(pool_size: nil)
    end

    it "sets it based on the max number of worker threads" do
      expect { subject }.to change { Gitlab::Database.config['pool'] }.from(nil).to(18)

      expect(ActiveRecord::Base.connection_db_config.pool).to eq(18)
    end
  end

  context "the existing pool size is smaller than the max number of worker threads" do
    before do
      stub_database_config(pool_size: 1)
    end

    it "sets it based on the max number of worker threads" do
      expect { subject }.to change { Gitlab::Database.config['pool'] }.from(1).to(18)

      expect(ActiveRecord::Base.connection_db_config.pool).to eq(18)
    end
  end

  context "and the existing pool size is larger than the max number of worker threads" do
    before do
      stub_database_config(pool_size: 100)
    end

    it "sets it based on the max number of worker threads" do
      expect { subject }.to change { Gitlab::Database.config['pool'] }.from(100).to(18)

      expect(ActiveRecord::Base.connection_db_config.pool).to eq(18)
    end
  end

  context "when specifying headroom through an ENV variable" do
    let(:headroom) { 15 }

    before do
      stub_database_config(pool_size: 1)
      stub_env("DB_POOL_HEADROOM", headroom)
    end

    it "adds headroom on top of the calculated size" do
      expect { subject }.to change { Gitlab::Database.config['pool'] }
                              .from(1)
                              .to(max_threads + headroom)

      expect(ActiveRecord::Base.connection_db_config.pool).to eq(max_threads + headroom)
    end
  end

  def stub_database_config(pool_size:)
    original_config = Gitlab::Database.config

    config = original_config.dup
    config['pool'] = pool_size

    allow(Gitlab::Database).to receive(:config).and_return(config)
  end
end
