# frozen_string_literal: true

require 'spec_helper'

describe 'Database config initializer' do
  subject do
    load Rails.root.join('config/initializers/database_config.rb')
  end

  before do
    allow(ActiveRecord::Base).to receive(:establish_connection)
  end

  context "when using Puma" do
    let(:puma) { double('puma') }
    let(:puma_options) { { max_threads: 8 } }

    before do
      allow(Gitlab::Runtime).to receive(:puma?).and_return(true)
      stub_const("Puma", puma)
      allow(puma).to receive_message_chain(:cli_config, :options).and_return(puma_options)
    end

    context "and no existing pool size is set" do
      before do
        stub_database_config(pool_size: nil)
      end

      it "sets it to the max number of worker threads" do
        expect { subject }.to change { Gitlab::Database.config['pool'] }.from(nil).to(8)
      end
    end

    context "and the existing pool size is smaller than the max number of worker threads" do
      before do
        stub_database_config(pool_size: 7)
      end

      it "sets it to the max number of worker threads" do
        expect { subject }.to change { Gitlab::Database.config['pool'] }.from(7).to(8)
      end
    end

    context "and the existing pool size is larger than the max number of worker threads" do
      before do
        stub_database_config(pool_size: 9)
      end

      it "keeps the configured pool size" do
        expect { subject }.not_to change { Gitlab::Database.config['pool'] }
      end
    end
  end

  context "when not using Puma" do
    before do
      stub_database_config(pool_size: 7)
    end

    it "does nothing" do
      expect { subject }.not_to change { Gitlab::Database.config['pool'] }
    end
  end

  def stub_database_config(pool_size:)
    config = {
      'adapter' => 'postgresql',
      'host' => 'db.host.com',
      'pool' => pool_size
    }.compact

    allow(Gitlab::Database).to receive(:config).and_return(config)
  end
end
