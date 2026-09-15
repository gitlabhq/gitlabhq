# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Gitlab::Database::PgAsh, feature_category: :database do
  describe '.install_sql' do
    let(:raw_script) do
      <<~SQL
        \\set ON_ERROR_STOP on
        begin;
        select '\\not a meta-command';
        commit;
      SQL
    end

    before do
      allow(File).to receive(:read)
        .with(Rails.root.join(described_class::INSTALL_SQL_PATH))
        .and_return(raw_script)
    end

    it 'strips only the psql meta-command lines' do
      expect(described_class.install_sql).to eq(<<~SQL)
        begin;
        select '\\not a meta-command';
        commit;
      SQL
    end
  end
end
