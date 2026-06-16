# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DiffPositionableNote, feature_category: :code_review_workflow do
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:merge_request) { create(:merge_request, source_project: project, target_project: project) }

  let(:diff_note) do
    create(:diff_note_on_merge_request, noteable: merge_request, project: project)
  end

  describe 'serialized position readers', :request_store do
    %i[original_position position change_position].each do |attribute|
      context "when #{attribute} column contains malformed YAML" do
        before do
          # Persist raw bytes that store fine but raise Psych::SyntaxError when YAML-loaded,
          # bypassing the typed writer.
          malformed_yaml = "{foo: bar, \n"
          Note.connection.execute(
            Note.sanitize_sql_array(["UPDATE notes SET #{attribute} = ? WHERE id = ?", malformed_yaml, diff_note.id])
          )
          diff_note.reload
        end

        it 'returns nil instead of raising', :aggregate_failures do
          allow(Gitlab::ErrorTracking).to receive(:track_exception)

          expect { diff_note.public_send(attribute) }.not_to raise_error
          expect(diff_note.public_send(attribute)).to be_nil
        end

        it 'tracks the exception once per request even on repeated reads' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
            instance_of(Psych::SyntaxError),
            hash_including(
              note_id: diff_note.id,
              noteable_type: diff_note.noteable_type,
              noteable_id: diff_note.noteable_id,
              attribute: attribute
            )
          ).once

          3.times { diff_note.public_send(attribute) }
        end
      end
    end
  end

  describe '#active?' do
    context 'when position is nil (e.g. corrupt YAML in the column)' do
      before do
        allow(diff_note).to receive(:position).and_return(nil)
      end

      it 'returns false without raising', :aggregate_failures do
        expect { diff_note.active? }.not_to raise_error
        expect(diff_note.active?).to be(false)
      end
    end
  end

  describe '#shas' do
    context 'when original_position is nil (corrupt YAML in the column)' do
      before do
        allow(diff_note).to receive(:original_position).and_return(nil)
      end

      it 'returns an empty array without raising', :aggregate_failures do
        expect { diff_note.shas }.not_to raise_error
        expect(diff_note.shas).to eq([])
      end
    end

    context 'when position is nil but original_position is present' do
      before do
        allow(diff_note).to receive(:position).and_return(nil)
      end

      it 'returns only the original_position shas without raising', :aggregate_failures do
        expect { diff_note.shas }.not_to raise_error
        expect(diff_note.shas).to contain_exactly(
          diff_note.original_position.base_sha,
          diff_note.original_position.start_sha,
          diff_note.original_position.head_sha
        )
      end
    end
  end

  describe '#diff_refs_match_commit' do
    let(:diff_note) { build(:diff_note_on_commit, project: project) }

    context 'when original_position is nil (corrupt YAML in the column)' do
      before do
        allow(diff_note).to receive(:original_position).and_return(nil)
      end

      it 'adds a validation error rather than raising', :aggregate_failures do
        expect { diff_note.diff_refs_match_commit }.not_to raise_error
        expect(diff_note.errors[:commit_id]).to include('does not match the diff refs')
      end
    end
  end
end
