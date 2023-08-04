# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'ActiveRecord::Relation patch for PostgreSQL WITH statements', feature_category: :database do
  describe 'ActiveRecord::Relation::WithChain#recursive' do
    subject(:relation) { User.with.recursive }

    it 'sets recursive value flag on the relation' do
      expect(relation.recursive_value).to eq(true)
    end

    it 'raises an error when #update_all is called' do
      expect { relation.update_all(attribute: 42) }.to raise_exception(ActiveRecord::ReadOnlyRecord)
    end
  end
end
