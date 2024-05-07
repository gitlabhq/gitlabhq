# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AsCte do
  let(:klass) do
    Class.new(ApplicationRecord) do
      include AsCte

      self.table_name = 'users'
    end
  end

  let(:query) { klass.where(id: [1, 2, 3]) }
  let(:name) { :klass_cte }

  describe '.as_cte' do
    subject { query.as_cte(name) }

    it { expect(subject).to be_a(Gitlab::SQL::CTE) }
    it { expect(subject.query).to eq(query) }
    it { expect(subject.table.name).to eq(name.to_s) }

    context 'with materialized parameter' do
      subject { query.as_cte(name, materialized: materialized).to_arel.to_sql }

      context 'as true' do
        let(:materialized) { true }

        it { expect(subject).to match(/MATERIALIZE/) }
      end

      context 'as false' do
        let(:materialized) { false }

        it { expect(subject).not_to match(/MATERIALIZE/) }
      end
    end
  end
end
