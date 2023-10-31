# frozen_string_literal: true

require 'spec_helper'

require_migration!

RSpec.describe FixDesignUserMentionsDesignIdNoteIdIndexForSelfManaged, feature_category: :database do
  let(:connection) { described_class.new.connection }
  let(:design_user_mentions) { table(:design_user_mentions) }

  shared_examples 'index `design_user_mentions_on_design_id_and_note_id_unique_index` already exists' do
    it 'does not swap the columns' do
      disable_migrations_output do
        reversible_migration do |migration|
          migration.before -> {
            index = connection.indexes(:design_user_mentions).find do |i|
              i.name == 'design_user_mentions_on_design_id_and_note_id_unique_index'
            end
            expect(index.columns).to eq(%w[design_id note_id])
          }

          migration.after -> {
            index = connection.indexes(:design_user_mentions).find do |i|
              i.name == 'design_user_mentions_on_design_id_and_note_id_unique_index'
            end
            expect(index.columns).to eq(%w[design_id note_id])
          }
        end
      end
    end
  end

  describe '#up' do
    before do
      # rubocop:disable RSpec/AnyInstanceOf
      allow_any_instance_of(described_class).to(
        receive(:com_or_dev_or_test_but_not_jh?).and_return(com_or_dev_or_test_but_not_jh?)
      )
      # rubocop:enable RSpec/AnyInstanceOf
    end

    context 'when GitLab.com, dev, or test' do
      let(:com_or_dev_or_test_but_not_jh?) { true }

      it_behaves_like 'index `design_user_mentions_on_design_id_and_note_id_unique_index` already exists'
    end

    context 'when self-managed instance' do
      let(:com_or_dev_or_test_but_not_jh?) { false }

      context "when index does not exist" do
        before do
          connection.execute('DROP INDEX IF EXISTS design_user_mentions_on_design_id_and_note_id_unique_index')
        end

        after do
          connection.execute('CREATE UNIQUE INDEX IF NOT EXISTS
            design_user_mentions_on_design_id_and_note_id_unique_index
            ON design_user_mentions (design_id, note_id)')
        end

        it 'creates the index' do
          disable_migrations_output { migrate! }

          index = connection.indexes(:design_user_mentions).find do |i|
            i.name == 'design_user_mentions_on_design_id_and_note_id_unique_index'
          end

          expect(index.columns).to eq(%w[design_id note_id])
        end
      end

      context "when index does exist" do
        it_behaves_like 'index `design_user_mentions_on_design_id_and_note_id_unique_index` already exists'
      end

      context "when index does exists on the int4 column" do
        before do
          connection.execute('DROP INDEX IF EXISTS design_user_mentions_on_design_id_and_note_id_unique_index')
          connection.execute(
            'ALTER TABLE design_user_mentions ADD COLUMN IF NOT EXISTS note_id_convert_to_bigint integer'
          )
          connection.execute('CREATE UNIQUE INDEX
            design_user_mentions_on_design_id_and_note_id_unique_index
            ON design_user_mentions (design_id, note_id_convert_to_bigint)')
        end

        after do
          connection.execute('DROP INDEX IF EXISTS design_user_mentions_on_design_id_and_note_id_unique_index')
          connection.execute('ALTER TABLE design_user_mentions DROP COLUMN IF EXISTS note_id_convert_to_bigint')
          connection.execute('CREATE UNIQUE INDEX
            design_user_mentions_on_design_id_and_note_id_unique_index
            ON design_user_mentions (design_id, note_id)')
        end

        it 'creates the index on the int8 column' do
          index = connection.indexes(:design_user_mentions).find do |i|
            i.name == 'design_user_mentions_on_design_id_and_note_id_unique_index'
          end

          expect(index.columns).to eq(%w[design_id note_id_convert_to_bigint])

          disable_migrations_output { migrate! }

          index = connection.indexes(:design_user_mentions).find do |i|
            i.name == 'design_user_mentions_on_design_id_and_note_id_unique_index'
          end

          expect(index.columns).to eq(%w[design_id note_id])
        end
      end
    end
  end
end
