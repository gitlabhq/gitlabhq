# frozen_string_literal: true

require 'spec_helper'

RSpec.describe UnnestedInFilters::Dsl do
  let(:test_model) do
    Class.new(ApplicationRecord) do
      include UnnestedInFilters::Dsl

      self.table_name = 'users'
    end
  end

  describe '#exists?' do
    let(:states) { %w[active banned] }

    subject { test_model.where(state: states).use_unnested_filters.exists? }

    context 'when there is no record in the database with given filters' do
      it { is_expected.to be_falsey }
    end

    context 'when there is a record in the database with given filters' do
      before do
        create(:user, state: :active)
      end

      it { is_expected.to be_truthy }
    end
  end
end
