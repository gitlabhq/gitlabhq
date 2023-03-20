# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventSaveType, feature_category: :audit_events do
  subject(:target) { Object.new.extend(described_class) }

  describe '#should_save_database? and #should_save_stream?' do
    using RSpec::Parameterized::TableSyntax

    where(:query_method, :query_param, :result) do
      :should_save_stream?    | :stream               | true
      :should_save_stream?    | :database_and_stream  | true
      :should_save_database?  | :database             | true
      :should_save_database?  | :database_and_stream  | true
      :should_save_stream?    | :database             | false
      :should_save_stream?    | nil                   | false
      :should_save_database?  | :stream               | false
      :should_save_database?  | nil                   | false
    end

    with_them do
      it 'returns corresponding results according to the query_method and query_param' do
        expect(target.send(query_method, query_param)).to eq result
      end
    end
  end
end
