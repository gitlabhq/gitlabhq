# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::Diagnostics::Checks::Base, feature_category: :database do
  describe '#execute' do
    let(:connection) { instance_double(ActiveRecord::ConnectionAdapters::PostgreSQLAdapter) }

    it 'requires the check to define it' do
      expect { described_class.new(connection).execute }.to raise_error(Gitlab::AbstractMethodError)
    end
  end
end
