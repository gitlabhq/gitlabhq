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

  describe '#stringified_hash?' do
    it 'returns true for a string-keyed Ruby Hash#inspect string' do
      expect(diff_note.stringified_hash?('{"base_sha"=>"abc"}')).to be(true)
    end

    it 'returns true for a symbol-keyed Ruby Hash#inspect string' do
      expect(diff_note.stringified_hash?('{:base_sha=>"abc"}')).to be(true)
    end

    it 'returns false for a normal YAML string' do
      expect(diff_note.stringified_hash?("--- !ruby/object\n")).to be(false)
    end

    it 'returns false for nil' do
      expect(diff_note.stringified_hash?(nil)).to be(false)
    end
  end

  describe '#recover_stringified_position' do
    let(:stringified_position) do
      '{"base_sha"=>"abc123", "start_sha"=>"abc123", "head_sha"=>"def456", ' \
        '"old_path"=>"README.md", "new_path"=>"README.md", ' \
        '"position_type"=>"text", "old_line"=>nil, "new_line"=>3}'
    end

    it 'returns a Gitlab::Diff::Position for a valid stringified hash', :aggregate_failures do
      result = diff_note.recover_stringified_position(stringified_position)

      expect(result).to be_a(Gitlab::Diff::Position)
      expect(result.base_sha).to eq('abc123')
      expect(result.head_sha).to eq('def456')
      expect(result.new_line).to eq(3)
    end

    it 'returns nil for a non-stringified-hash string' do
      expect(diff_note.recover_stringified_position('not a hash')).to be_nil
    end

    it 'returns nil for nil' do
      expect(diff_note.recover_stringified_position(nil)).to be_nil
    end

    context 'when recovery raises an unexpected error', :request_store do
      before do
        allow(Gitlab::Json).to receive(:safe_parse).and_raise(StandardError, 'boom')
      end

      it 'tracks the exception with the attribute and returns nil', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
          instance_of(StandardError),
          hash_including(note_id: diff_note.id, attribute: :position)
        ).once

        expect(diff_note.recover_stringified_position(stringified_position, :position)).to be_nil
      end

      it 'dedupes the tracked exception per note within a request' do
        expect(Gitlab::ErrorTracking).to receive(:track_exception).once

        3.times { diff_note.recover_stringified_position(stringified_position, :position) }
      end
    end

    context 'when a value contains the hash-rocket sequence' do
      let(:stringified_position) do
        '{"base_sha"=>"abc123", "start_sha"=>"abc123", "head_sha"=>"def456", ' \
          '"old_path"=>"a=>b.rb", "new_path"=>"a=>b.rb", ' \
          '"position_type"=>"text", "old_line"=>nil, "new_line"=>3}'
      end

      it 'preserves the value verbatim instead of corrupting it', :aggregate_failures do
        result = diff_note.recover_stringified_position(stringified_position)

        expect(result).to be_a(Gitlab::Diff::Position)
        expect(result.old_path).to eq('a=>b.rb')
        expect(result.new_path).to eq('a=>b.rb')
      end
    end

    context 'when the top-level hash is symbol-keyed' do
      let(:stringified_position) do
        '{:base_sha=>"abc123", :start_sha=>"abc123", :head_sha=>"def456", ' \
          ':old_path=>"README.md", :new_path=>"README.md", ' \
          ':position_type=>"text", :old_line=>nil, :new_line=>3}'
      end

      it 'recovers the position', :aggregate_failures do
        result = diff_note.recover_stringified_position(stringified_position)

        expect(result).to be_a(Gitlab::Diff::Position)
        expect(result.base_sha).to eq('abc123')
        expect(result.head_sha).to eq('def456')
        expect(result.new_line).to eq(3)
      end
    end

    context 'when the hash has a string-keyed multi-line line_range' do
      let(:stringified_position) do
        '{"base_sha"=>"abc123", "start_sha"=>"abc123", "head_sha"=>"def456", ' \
          '"old_path"=>"README.md", "new_path"=>"README.md", "position_type"=>"text", ' \
          '"old_line"=>nil, "new_line"=>3, ' \
          '"line_range"=>{"start"=>{"line_code"=>"abc_0_1", "type"=>"new", "new_line"=>1}, ' \
          '"end"=>{"line_code"=>"abc_0_3", "type"=>"new", "new_line"=>3}}}'
      end

      it 'recovers the position with its line_range', :aggregate_failures do
        result = diff_note.recover_stringified_position(stringified_position)

        expect(result).to be_a(Gitlab::Diff::Position)
        expect(result.line_range['start']['new_line']).to eq(1)
        expect(result.line_range['end']['new_line']).to eq(3)
      end
    end

    context 'when the hash has a symbol-keyed nested line_range' do
      let(:stringified_position) do
        '{"base_sha"=>"abc123", "start_sha"=>"abc123", "head_sha"=>"def456", ' \
          '"old_path"=>"README.md", "new_path"=>"README.md", "position_type"=>"text", ' \
          '"old_line"=>nil, "new_line"=>3, ' \
          '"line_range"=>{:start=>{:line_code=>"abc_0_1", :type=>"new", :new_line=>1}, ' \
          ':end=>{:line_code=>"abc_0_3", :type=>"new", :new_line=>3}}}'
      end

      it 'recovers the position with its line_range', :aggregate_failures do
        result = diff_note.recover_stringified_position(stringified_position)

        expect(result).to be_a(Gitlab::Diff::Position)
        expect(result.line_range['start']['new_line']).to eq(1)
        expect(result.line_range['end']['new_line']).to eq(3)
      end
    end
  end

  describe 'position reader recovery from stringified-hash columns', :request_store do
    let(:stringified_position) do
      '{"base_sha"=>"abc123", "start_sha"=>"abc123", "head_sha"=>"def456", ' \
        '"old_path"=>"README.md", "new_path"=>"README.md", ' \
        '"position_type"=>"text", "old_line"=>nil, "new_line"=>3}'
    end

    %i[original_position position change_position].each do |attribute|
      context "when #{attribute} column contains a stringified Ruby Hash" do
        before do
          Note.connection.execute(
            Note.sanitize_sql_array(
              ["UPDATE notes SET #{attribute} = ? WHERE id = ?", stringified_position, diff_note.id]
            )
          )
          diff_note.reload
        end

        it 'returns a Gitlab::Diff::Position without raising', :aggregate_failures do
          allow(Gitlab::ErrorTracking).to receive(:track_exception)

          result = diff_note.public_send(attribute)

          expect(result).to be_a(Gitlab::Diff::Position)
          expect(result.base_sha).to eq('abc123')
          expect(result.new_line).to eq(3)
        end

        it 'does not persist the recovered value' do
          allow(Gitlab::ErrorTracking).to receive(:track_exception)
          diff_note.public_send(attribute)

          raw = Note.connection.select_value(
            "SELECT #{attribute} FROM notes WHERE id = #{diff_note.id}"
          )
          expect(raw).to eq(stringified_position)
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
