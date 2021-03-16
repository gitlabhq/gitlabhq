# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Pagination::Keyset::QueryBuilder do
  context 'when number of ordering fields is 0' do
    it 'raises an error' do
      expect { described_class.new(Issue.arel_table, [], {}, :after) }
        .to raise_error(ArgumentError, 'No ordering scopes have been supplied')
    end
  end

  describe '#conditions' do
    let(:relation) { Issue.order(relative_position: :desc).order(:id) }
    let(:order_list) { Gitlab::Graphql::Pagination::Keyset::OrderInfo.build_order_list(relation) }
    let(:arel_table) { Issue.arel_table }
    let(:builder) { described_class.new(arel_table, order_list, decoded_cursor, before_or_after) }
    let(:before_or_after) { :after }

    context 'when only a single ordering' do
      let(:relation) { Issue.order(id: :desc) }

      context 'when the value is nil' do
        let(:decoded_cursor) { { 'id' => nil } }

        it 'raises an error' do
          expect { builder.conditions }
            .to raise_error(Gitlab::Graphql::Errors::ArgumentError, 'Before/after cursor invalid: `nil` was provided as only sortable value')
        end
      end

      context 'when value is not nil' do
        let(:decoded_cursor) { { 'id' => 100 } }
        let(:conditions) { builder.conditions }

        context 'when :after' do
          it 'generates the correct condition' do
            expect(conditions.strip).to eq '("issues"."id" < 100)'
          end
        end

        context 'when :before' do
          let(:before_or_after) { :before }

          it 'generates the correct condition' do
            expect(conditions.strip).to eq '("issues"."id" > 100)'
          end
        end
      end
    end

    context 'when two orderings' do
      let(:decoded_cursor) { { 'relative_position' => 1500, 'id' => 100 } }

      context 'when no values are nil' do
        context 'when :after' do
          it 'generates the correct condition' do
            conditions = builder.conditions

            expect(conditions).to include '"issues"."relative_position" < 1500'
            expect(conditions).to include '"issues"."id" > 100'
            expect(conditions).to include 'OR ("issues"."relative_position" IS NULL)'
          end
        end

        context 'when :before' do
          let(:before_or_after) { :before }

          it 'generates the correct condition' do
            conditions = builder.conditions

            expect(conditions).to include '("issues"."relative_position" > 1500)'
            expect(conditions).to include '"issues"."id" < 100'
            expect(conditions).to include '"issues"."relative_position" = 1500'
          end
        end
      end

      context 'when first value is nil' do
        let(:decoded_cursor) { { 'relative_position' => nil, 'id' => 100 } }

        context 'when :after' do
          it 'generates the correct condition' do
            conditions = builder.conditions

            expect(conditions).to include '"issues"."relative_position" IS NULL'
            expect(conditions).to include '"issues"."id" > 100'
          end
        end

        context 'when :before' do
          let(:before_or_after) { :before }

          it 'generates the correct condition' do
            conditions = builder.conditions

            expect(conditions).to include '"issues"."relative_position" IS NULL'
            expect(conditions).to include '"issues"."id" < 100'
            expect(conditions).to include 'OR ("issues"."relative_position" IS NOT NULL)'
          end
        end
      end
    end

    context 'when sorting using LOWER' do
      let(:relation) { Project.order(Arel::Table.new(:projects)['name'].lower.asc).order(:id) }
      let(:arel_table) { Project.arel_table }
      let(:decoded_cursor) { { 'name' => 'Test', 'id' => 100 } }

      context 'when no values are nil' do
        context 'when :after' do
          it 'generates the correct condition' do
            conditions = builder.conditions

            expect(conditions).to include '(LOWER("projects"."name") > \'test\')'
            expect(conditions).to include '"projects"."id" > 100'
            expect(conditions).to include 'OR (LOWER("projects"."name") IS NULL)'
          end
        end

        context 'when :before' do
          let(:before_or_after) { :before }

          it 'generates the correct condition' do
            conditions = builder.conditions

            expect(conditions).to include '(LOWER("projects"."name") < \'test\')'
            expect(conditions).to include '"projects"."id" < 100'
            expect(conditions).to include 'LOWER("projects"."name") = \'test\''
          end
        end
      end
    end
  end
end
