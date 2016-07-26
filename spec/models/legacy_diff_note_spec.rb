require 'spec_helper'

describe LegacyDiffNote, models: true do
  describe "Commit diff line notes" do
    let!(:note) { create(:legacy_diff_note_on_commit, note: "+1 from me") }
    let!(:commit) { note.noteable }

    it "should save a valid note" do
      expect(note.commit_id).to eq(commit.id)
      expect(note.noteable.id).to eq(commit.id)
    end

    it "should be recognized by #legacy_diff_note?" do
      expect(note).to be_legacy_diff_note
    end
  end

  describe '#active?' do
    it 'is always true when the note has no associated diff line' do
      note = build(:legacy_diff_note_on_merge_request)

      expect(note).to receive(:diff_line).and_return(nil)

      expect(note).to be_active
    end

    it 'is never true when the note has no noteable associated' do
      note = build(:legacy_diff_note_on_merge_request)

      expect(note).to receive(:diff_line).and_return(double)
      expect(note).to receive(:noteable).and_return(nil)

      expect(note).not_to be_active
    end

    it 'returns the memoized value if defined' do
      note = build(:legacy_diff_note_on_merge_request)

      note.instance_variable_set(:@active, 'foo')
      expect(note).not_to receive(:find_noteable_diff)

      expect(note.active?).to eq 'foo'
    end

    context 'for a merge request noteable' do
      it 'is false when noteable has no matching diff' do
        merge = build_stubbed(:merge_request, :simple)
        note = build(:legacy_diff_note_on_merge_request, noteable: merge)

        allow(note).to receive(:diff_line).and_return(double)
        expect(note).to receive(:find_noteable_diff).and_return(nil)

        expect(note).not_to be_active
      end

      it 'is true when noteable has a matching diff' do
        merge = create(:merge_request, :simple)

        # Generate a real line_code value so we know it will match. We use a
        # random line from a random diff just for funsies.
        diff = merge.diffs.to_a.sample
        line = Gitlab::Diff::Parser.new.parse(diff.diff.each_line).to_a.sample
        code = Gitlab::Diff::LineCode.generate(diff.new_path, line.new_pos, line.old_pos)

        # We're persisting in order to trigger the set_diff callback
        note = create(:legacy_diff_note_on_merge_request,  noteable: merge,
                                                           line_code: code,
                                                           project: merge.source_project)

        # Make sure we don't get a false positive from a guard clause
        expect(note).to receive(:find_noteable_diff).and_call_original
        expect(note).to be_active
      end
    end
  end
end
