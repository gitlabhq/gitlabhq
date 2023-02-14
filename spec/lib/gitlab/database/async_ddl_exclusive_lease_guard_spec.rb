# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncDdlExclusiveLeaseGuard, feature_category: :database do
  let(:helper_class) do
    Class.new do
      include Gitlab::Database::AsyncDdlExclusiveLeaseGuard

      attr_reader :connection_db_config

      def initialize(connection_db_config)
        @connection_db_config = connection_db_config
      end
    end
  end

  describe '#lease_key' do
    let(:helper) { helper_class.new(connection_db_config) }
    let(:lease_key) { "gitlab/database/asyncddl/actions/#{database_name}" }

    context 'with CI database connection' do
      let(:connection_db_config) { Ci::ApplicationRecord.connection_db_config }
      let(:database_name) { Gitlab::Database::CI_DATABASE_NAME }

      before do
        skip_if_multiple_databases_not_setup
      end

      it { expect(helper.lease_key).to eq(lease_key) }
    end

    context 'with MAIN database connection' do
      let(:connection_db_config) { ApplicationRecord.connection_db_config }
      let(:database_name) { Gitlab::Database::MAIN_DATABASE_NAME }

      it { expect(helper.lease_key).to eq(lease_key) }
    end
  end
end
