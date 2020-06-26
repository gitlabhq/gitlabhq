# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::DynamicModelHelpers do
  describe '#define_batchable_model' do
    subject { including_class.new.define_batchable_model(table_name) }

    let(:including_class) { Class.new.include(described_class) }
    let(:table_name) { 'projects' }

    it 'is an ActiveRecord model' do
      expect(subject.ancestors).to include(ActiveRecord::Base)
    end

    it 'includes EachBatch' do
      expect(subject.included_modules).to include(EachBatch)
    end

    it 'has the correct table name' do
      expect(subject.table_name).to eq(table_name)
    end

    it 'has the inheritance type column disable' do
      expect(subject.inheritance_column).to eq('_type_disabled')
    end
  end
end
