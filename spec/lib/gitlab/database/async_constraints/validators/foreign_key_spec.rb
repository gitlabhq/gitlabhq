# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::AsyncConstraints::Validators::ForeignKey, feature_category: :database do
  it_behaves_like 'async constraints validation' do
    let(:constraint_type) { :foreign_key }

    before do
      connection.create_table(table_name) do |t|
        t.references :parent, foreign_key: { to_table: table_name, validate: false, name: constraint_name }
      end
    end

    context 'with fully qualified table names' do
      let(:validation) do
        create(:postgres_async_constraint_validation,
          table_name: "public.#{table_name}",
          name: constraint_name,
          constraint_type: constraint_type
        )
      end

      it 'validates the constraint' do
        allow(connection).to receive(:execute).and_call_original

        expect(connection).to receive(:execute)
          .with(/ALTER TABLE "public"."#{table_name}" VALIDATE CONSTRAINT "#{constraint_name}";/)
          .ordered.and_call_original

        subject.perform
      end
    end
  end
end
