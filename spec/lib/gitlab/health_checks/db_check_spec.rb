# frozen_string_literal: true

require 'spec_helper'
require_relative './simple_check_shared'

RSpec.describe Gitlab::HealthChecks::DbCheck do
  include_examples 'simple_check', 'db_ping', 'Db', Gitlab::Database.database_base_models.size

  context 'with multiple databases' do
    subject { described_class.readiness }

    before do
      allow(Gitlab::Database).to receive(:database_base_models)
        .and_return({ main: ApplicationRecord, ci: Ci::ApplicationRecord }.with_indifferent_access)
    end

    it 'checks multiple databases' do
      expect(ApplicationRecord.connection).to receive(:select_value).with('SELECT 1').and_call_original
      expect(Ci::ApplicationRecord.connection).to receive(:select_value).with('SELECT 1').and_call_original
      expect(subject).to have_attributes(success: true)
    end
  end
end
