# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::ProjectImportFailedRelation do
  describe '#as_json' do
    subject { entity.as_json }

    let(:import_failure) { build(:import_failure) }
    let(:entity) { described_class.new(import_failure) }

    it 'includes basic fields', :aggregate_failures do
      expect(subject).to eq(
        id: import_failure.id,
        created_at: import_failure.created_at,
        exception_class: import_failure.exception_class,
        exception_message: nil,
        relation_name: import_failure.relation_key,
        source: import_failure.source
      )
    end
  end
end
