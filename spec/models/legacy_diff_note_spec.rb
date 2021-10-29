# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LegacyDiffNote do
  describe '#to_ability_name' do
    subject { described_class.new.to_ability_name }

    it { is_expected.to eq('note') }
  end

  describe 'callbacks' do
    describe '#set_diff' do
      let(:note) do
        build(:legacy_diff_note_on_merge_request, st_diff: '_st_diff_').tap do |record|
          record.instance_variable_set(:@diff, {})
        end
      end

      context 'when not importing' do
        it 'updates st_diff' do
          note.save!(validate: false)

          expect(note.st_diff).to eq({})
        end
      end

      context 'when importing' do
        before do
          note.importing = true
        end

        it 'does not update st_diff' do
          note.save!(validate: false)

          expect(note.st_diff).to eq('_st_diff_')
        end

        context 'when st_diff is blank' do
          before do
            note.st_diff = nil
          end

          it 'updates st_diff' do
            note.save!(validate: false)

            expect(note.st_diff).to eq({})
          end
        end
      end
    end
  end
end
