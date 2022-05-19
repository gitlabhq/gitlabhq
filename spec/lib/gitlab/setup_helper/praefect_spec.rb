# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SetupHelper::Praefect do
  describe '.configuration_toml' do
    let(:opt_per_repo) do
      { per_repository: true,
        pghost: 'my-host',
        pgport: 555432,
        pguser: 'me' }
    end

    it 'defaults to in memory queue' do
      toml = described_class.configuration_toml('/here', nil, {})

      expect(toml).to match(/i_understand_my_election_strategy_is_unsupported_and_will_be_removed_without_warning/)
      expect(toml).to match(/memory_queue_enabled = true/)
      expect(toml).to match(/election_strategy = "local"/)
      expect(toml).not_to match(/\[database\]/)
    end

    it 'provides database details if wanted' do
      toml = described_class.configuration_toml('/here', nil, opt_per_repo)

      expect(toml).not_to match(/i_understand_my_election_strategy_is_unsupported_and_will_be_removed_without_warning/)
      expect(toml).not_to match(/memory_queue_enabled = true/)
      expect(toml).to match(/\[database\]/)
      expect(toml).to match(/election_strategy = "per_repository"/)
    end

    %i[pghost pgport pguser].each do |pg_key|
      it "fails when #{pg_key} is missing" do
        opt = opt_per_repo.dup
        opt.delete(pg_key)

        expect do
          described_class.configuration_toml('/here', nil, opt)
        end.to raise_error(KeyError)
      end

      it "uses the provided #{pg_key}" do
        toml = described_class.configuration_toml('/here', nil, opt_per_repo)

        expect(toml).to match(/#{pg_key.to_s.delete_prefix('pg')} = "?#{opt_per_repo[pg_key]}"?/)
      end
    end

    it 'defaults to praefect_test if dbname is missing' do
      toml = described_class.configuration_toml('/here', nil, opt_per_repo)

      expect(toml).to match(/dbname = "praefect_test"/)
    end

    it 'uses the provided dbname' do
      opt = opt_per_repo.merge(dbname: 'my_db')

      toml = described_class.configuration_toml('/here', nil, opt)

      expect(toml).to match(/dbname = "my_db"/)
    end
  end

  describe '.get_config_path' do
    it 'defaults to praefect.config.toml' do
      expect(described_class).to receive(:generate_configuration).with(anything, '/tmp/praefect.config.toml', anything)

      described_class.create_configuration('/tmp', {})
    end

    it 'takes the provided config_filename' do
      opt = { config_filename: 'yo.toml' }

      expect(described_class).to receive(:generate_configuration).with(anything, '/tmp/yo.toml', anything)

      described_class.create_configuration('/tmp', {}, options: opt)
    end
  end
end
