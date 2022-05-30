# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples Integrations::BaseDataFields do
  describe 'associations' do
    it { is_expected.to belong_to :integration }
  end

  describe '#to_database_hash' do
    it 'does not include certain attributes' do
      hash = described_class.new.to_database_hash

      expect(hash.keys).not_to include('id', 'service_id', 'integration_id', 'created_at', 'updated_at')
    end
  end
end
