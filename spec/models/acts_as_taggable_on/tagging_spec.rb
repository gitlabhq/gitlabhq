# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ActsAsTaggableOn::Tagging do
  it 'has the same connection as Ci::ApplicationRecord' do
    query = 'select current_database()'

    expect(described_class.connection.execute(query).first).to eq(Ci::ApplicationRecord.connection.execute(query).first)
    expect(described_class.retrieve_connection.execute(query).first).to eq(Ci::ApplicationRecord.retrieve_connection.execute(query).first)
  end

  it 'has the same sticking as Ci::ApplicationRecord' do
    expect(described_class.sticking).to eq(Ci::ApplicationRecord.sticking)
  end
end
