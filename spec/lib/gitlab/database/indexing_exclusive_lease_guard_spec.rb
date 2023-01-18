# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::IndexingExclusiveLeaseGuard, feature_category: :database do
  let(:helper_class) do
    Class.new do
      include Gitlab::Database::IndexingExclusiveLeaseGuard

      attr_reader :connection

      def initialize(connection)
        @connection = connection
      end
    end
  end

  describe '#lease_key' do
    let(:helper) { helper_class.new(connection) }
    let(:lease_key) { "gitlab/database/indexing/actions/#{database_name}" }

    context 'with CI database connection' do
      let(:connection) { Ci::ApplicationRecord.connection }
      let(:database_name) { Gitlab::Database::CI_DATABASE_NAME }

      before do
        skip_if_multiple_databases_not_setup
      end

      it { expect(helper.lease_key).to eq(lease_key) }
    end

    context 'with MAIN database connection' do
      let(:connection) { ApplicationRecord.connection }
      let(:database_name) { Gitlab::Database::MAIN_DATABASE_NAME }

      it { expect(helper.lease_key).to eq(lease_key) }
    end
  end
end
