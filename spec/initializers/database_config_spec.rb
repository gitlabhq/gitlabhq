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

  context 'when no custom headroom is specified' do
    it 'sets the pool size based on the number of worker threads' do
      old = ActiveRecord::Base.connection_db_config.pool

      expect(old).not_to eq(18)

      expect { subject }
        .to change { ActiveRecord::Base.connection_db_config.pool }
        .from(old)
        .to(18)
    end

    it 'overwrites custom pool settings' do
      config = Gitlab::Database.config.merge(pool: 42)

      allow(Gitlab::Database.main).to receive(:config).and_return(config)
      subject

      expect(ActiveRecord::Base.connection_db_config.pool).to eq(18)
    end
  end

  context "when specifying headroom through an ENV variable" do
    let(:headroom) { 15 }

    before do
      stub_env("DB_POOL_HEADROOM", headroom)
    end

    it "adds headroom on top of the calculated size" do
      old = ActiveRecord::Base.connection_db_config.pool

      expect { subject }
        .to change { ActiveRecord::Base.connection_db_config.pool }
        .from(old)
        .to(23)
    end
  end
end
