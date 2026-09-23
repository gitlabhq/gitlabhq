# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DraftNotes::TraceMergeHeadPositionService, feature_category: :code_review_workflow do
  # Regression coverage for https://gitlab.com/gitlab-org/gitlab/-/issues/590869: the target gains lines ABOVE the
  # commented line, so the stored 3-way line_code matches nothing in the rendered merge_head diff.
  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:user) { project.first_owner }
  let_it_be(:path) { 'files/ruby/shifted.rb' }

  let_it_be(:merge_request) do
    default_branch = project.default_branch

    project.repository.create_file(
      user, path, "def add(a, b)\n  a + b\nend\n",
      message: 'base', branch_name: default_branch)
    project.repository.add_branch(user, 'mh-shift-source', default_branch)
    project.repository.update_file(
      user, path, "def add(a, b)\n  a + b\nend\n\ndef sum(arr)\n  arr.sum\nend\n",
      message: 'source adds sum', branch_name: 'mh-shift-source')
    # Advance the target ABOVE the added line so the new_line shifts in the merge result.
    project.repository.update_file(
      user, path,
      "# frozen_string_literal: true\n# generated header\n\ndef add(a, b)\n  a + b\nend\n",
      message: 'target prepends header', branch_name: default_branch)

    mr = create(:merge_request, source_project: project, target_project: project,
      source_branch: 'mh-shift-source', target_branch: default_branch)

    MergeRequests::MergeToRefService.new(project: project, current_user: user).execute(mr)
    mr.create_merge_head_diff!
    mr.update_column(:merge_status, 'can_be_merged')
    mr.reload
    mr
  end

  let(:source_sum_line) do
    file = merge_request.diffs.diff_files.find { |f| f.new_path == path }
    file.diff_lines.find { |line| line.added? && line.text.include?('def sum') }.new_pos
  end

  let!(:draft) do
    create(:draft_note_on_text_diff, merge_request: merge_request, author: user,
      path: path, line_number: source_sum_line)
  end

  let(:rendered_merge_head_file) do
    merge_request.merge_head_diff.diffs.diff_files.find { |f| f.new_path == path }
  end

  let(:rendered_line_codes) do
    rendered_merge_head_file.diff_lines.filter_map { |line| rendered_merge_head_file.line_code(line) }
  end

  # Refs of an earlier diff version (start_sha at the merge base), unlike both merge_request.diff_refs and the
  # merge_head refs.
  let(:earlier_refs) do
    current_refs = merge_request.diff_refs

    Gitlab::Diff::DiffRefs.new(
      base_sha: current_refs.base_sha,
      start_sha: current_refs.base_sha,
      head_sha: current_refs.head_sha)
  end

  describe '#execute' do
    it 'overwrites the in-memory line_code with one the merge_head diff contains' do
      original = draft.line_code

      described_class.new(merge_request, [draft]).execute

      expect(draft.line_code).to be_present
      expect(draft.line_code).not_to eq(original)
      expect(rendered_line_codes).to include(draft.line_code)
    end

    # The legacy renderer places a draft by line_code, rapid diffs by position + diff_refs, so the
    # retraced position has to be served both ways or the note is invisible in one of them.
    it 'sets the merge_head position the rendered diff matches on', :aggregate_failures do
      described_class.new(merge_request, [draft]).execute

      position = draft.merge_head_position

      expect(position.diff_refs).to eq(merge_request.merge_head_diff.diff_refs)
      expect(position.line_code(project.repository)).to eq(draft.line_code)
      expect(rendered_line_codes).to include(position.line_code(project.repository))
    end

    it 'does not persist the line_code change' do
      original = draft.line_code

      described_class.new(merge_request, [draft]).execute
      traced = draft.line_code

      expect(traced).not_to eq(original)
      expect(draft.reload.line_code).to eq(original)
    end

    it 'accepts a single draft note as well as a collection' do
      original = draft.line_code

      described_class.new(merge_request, draft).execute

      expect(draft.line_code).not_to eq(original)
    end

    it 'builds a single PositionTracer for the whole collection' do
      second = create(:draft_note_on_text_diff, merge_request: merge_request, author: user,
        path: path, line_number: source_sum_line)

      expect(Gitlab::Diff::PositionTracer).to receive(:new).once.and_call_original

      described_class.new(merge_request, [draft, second]).execute
    end

    context 'when the draft_note_merge_head_line_code feature flag is disabled' do
      before do
        stub_feature_flags(draft_note_merge_head_line_code: false)
      end

      it 'leaves the stored line_code untouched and builds no tracer' do
        original = draft.line_code
        expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

        described_class.new(merge_request, [draft]).execute

        expect(draft.line_code).to eq(original)
      end
    end

    context 'when the merge request has no diffable merge ref' do
      it 'leaves the stored line_code untouched and builds no tracer' do
        allow(merge_request).to receive(:diffable_merge_ref?).and_return(false)
        original = draft.line_code
        expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

        described_class.new(merge_request, [draft]).execute

        expect(draft.line_code).to eq(original)
      end
    end

    # Guards in #tracer: a vanished merge ref, a parentless one, or missing diff refs each leave the draft untouched.
    context 'when the merge ref cannot provide diff refs' do
      before do
        allow(merge_request).to receive(:merge_ref_head).and_return(merge_ref_head)
      end

      shared_examples 'builds no tracer' do
        it 'leaves the stored line_code untouched and builds no tracer' do
          original = draft.line_code
          expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

          described_class.new(merge_request, [draft]).execute

          expect(draft.line_code).to eq(original)
        end
      end

      context 'when the merge ref head is missing' do
        let(:merge_ref_head) { nil }

        it_behaves_like 'builds no tracer'
      end

      context 'when the merge ref head has no parent' do
        let(:merge_ref_head) do
          merge_request.merge_ref_head.tap { |commit| allow(commit).to receive(:parent_ids).and_return([]) }
        end

        it_behaves_like 'builds no tracer'
      end

      context 'when the merge request has no diff refs' do
        let(:merge_ref_head) { merge_request.merge_ref_head }

        before do
          allow(merge_request).to receive(:diff_refs).and_return(nil)
        end

        it_behaves_like 'builds no tracer'
      end
    end

    context 'when a draft note is not on a diff' do
      it 'skips it and still retraces the diff draft in the same call', :aggregate_failures do
        plain_draft = create(:draft_note, merge_request: merge_request, author: user)
        current_line_code = draft.line_code

        described_class.new(merge_request, [plain_draft, draft]).execute

        expect(plain_draft.line_code).to be_nil
        expect(plain_draft.merge_head_position).to be_nil
        expect(draft.line_code).not_to eq(current_line_code)
      end
    end

    context 'when the tracer cannot map the position onto the merge_head diff' do
      using RSpec::Parameterized::TableSyntax

      where(:trace_result) do
        [
          [{ outdated: true }],
          [{ outdated: false, position: nil }]
        ]
      end

      with_them do
        before do
          allow_next_instance_of(Gitlab::Diff::PositionTracer) do |tracer|
            allow(tracer).to receive(:trace).and_return(trace_result)
          end
        end

        it 'leaves the draft untouched', :aggregate_failures do
          original = draft.line_code

          described_class.new(merge_request, [draft]).execute

          expect(draft.line_code).to eq(original)
          expect(draft.merge_head_position).to be_nil
        end
      end
    end

    context 'when the traced position has no line_code' do
      it 'sets the merge_head position but keeps the stored line_code', :aggregate_failures do
        traced_position = instance_double(Gitlab::Diff::Position, line_code: nil)
        allow_next_instance_of(Gitlab::Diff::PositionTracer) do |tracer|
          allow(tracer).to receive(:trace).and_return(outdated: false, position: traced_position)
        end
        original = draft.line_code

        described_class.new(merge_request, [draft]).execute

        expect(draft.line_code).to eq(original)
        expect(draft.merge_head_position).to eq(traced_position)
      end
    end

    # Above the cap tracing is skipped for the whole collection, not a subset, so every draft behaves the same.
    context 'when more files are commented on than the file limit' do
      let!(:extra_drafts) do
        Array.new(3) do |i|
          create(:draft_note_on_text_diff, merge_request: merge_request, author: user,
            path: "files/ruby/extra_#{i}.rb", line_number: 1)
        end
      end

      before do
        stub_const("#{described_class}::FILE_LIMIT", 2)
      end

      it 'skips tracing for the whole collection, logs it, and keeps the stored line_code',
        :aggregate_failures do
        allow(Gitlab::AppLogger).to receive(:info).and_call_original
        original = draft.line_code

        expect(Gitlab::Diff::PositionTracer).not_to receive(:new)

        described_class.new(merge_request, [draft, *extra_drafts]).execute

        expect(draft.line_code).to eq(original)
        expect(Gitlab::AppLogger).to have_received(:info).with(
          hash_including(
            'class_name' => described_class.name,
            'message' => 'Draft note merge_head line_code tracing skipped: file limit exceeded',
            'commented_file_count' => 4,
            'file_limit' => 2
          )
        )
      end
    end

    # Only traceable drafts count toward FILE_LIMIT, or enough outdated comments could push a request over the cap
    # and skip tracing for current-diff notes, reintroducing #590869 with no abuse required.
    context 'when untraceable notes would exceed the file limit but traceable ones do not' do
      before do
        stub_const("#{described_class}::FILE_LIMIT", 2)
      end

      it 'ignores untraceable notes for the cap and still retraces the current-diff note',
        :aggregate_failures do
        stored_line_code = "#{'a' * 40}_10_10"
        # Naively counted, 1 current + 3 outdated files = 4 > FILE_LIMIT (2); only the current file should count.
        outdated_drafts = Array.new(3) do |i|
          create(:draft_note_on_text_diff, merge_request: merge_request, author: user,
            path: "files/ruby/outdated_#{i}.rb", line_number: 1, diff_refs: earlier_refs,
            line_code: stored_line_code)
        end
        current_line_code = draft.line_code

        described_class.new(merge_request, [draft, *outdated_drafts]).execute

        expect(draft.line_code).not_to eq(current_line_code)
        expect(outdated_drafts.map(&:line_code)).to all(eq(stored_line_code))
      end
    end

    # A draft the tracer cannot map must be left alone: its stored line_code already matches the diff it was created
    # against. #traceable_position returns nil for these.
    context 'when neither of a draft note stored positions targets the current MR diff' do
      let(:stored_line_code) { "#{'a' * 40}_10_10" }

      it 'leaves a draft note on a commit untouched', :aggregate_failures do
        commit = merge_request.commits.first
        commit_draft = create(:draft_note_on_text_diff, merge_request: merge_request, author: user,
          path: path, line_number: source_sum_line, diff_refs: commit.diff_refs,
          commit_id: commit.id, line_code: stored_line_code)

        described_class.new(merge_request, [commit_draft]).execute

        expect(commit_draft.line_code).to eq(stored_line_code)
        expect(commit_draft.merge_head_position).to be_nil
      end

      # A file the current diff no longer has, so update_position cannot bring the note forward and neither position
      # is traceable. The current draft in the same call proves a tracer existed.
      it 'leaves an outdated earlier-version draft untouched while retracing a current-version draft',
        :aggregate_failures do
        outdated_draft = create(:draft_note_on_text_diff, merge_request: merge_request, author: user,
          path: 'files/ruby/no_longer_in_the_diff.rb', line_number: 1, diff_refs: earlier_refs,
          line_code: stored_line_code)
        current_line_code = draft.line_code

        described_class.new(merge_request, [draft, outdated_draft]).execute

        expect(outdated_draft.line_code).to eq(stored_line_code)
        expect(outdated_draft.merge_head_position).to be_nil
        expect(draft.line_code).not_to eq(current_line_code)
      end
    end

    # The shape the UI produces (diffs/store/utils.js `getFormData`): original_position keeps merge_head refs and
    # update_position normalises `position` onto merge_request.diff_refs. Own branches so the target can advance later.
    context 'when the draft note was created against the rendered merge_head diff' do
      let_it_be(:ui_path) { 'files/ruby/ui_shifted.rb' }

      let_it_be(:ui_merge_request) do
        project.repository.add_branch(user, 'ui-shift-target', project.default_branch)
        project.repository.create_file(
          user, ui_path, "def add(a, b)\n  a + b\nend\n",
          message: 'base', branch_name: 'ui-shift-target')
        project.repository.add_branch(user, 'ui-shift-source', 'ui-shift-target')
        project.repository.update_file(
          user, ui_path, "def add(a, b)\n  a + b\nend\n\ndef sum(arr)\n  arr.sum\nend\n",
          message: 'source adds sum', branch_name: 'ui-shift-source')

        mr = create(:merge_request, source_project: project, target_project: project,
          source_branch: 'ui-shift-source', target_branch: 'ui-shift-target')

        MergeRequests::MergeToRefService.new(project: project, current_user: user).execute(mr)
        mr.create_merge_head_diff!
        mr.update_column(:merge_status, 'can_be_merged')
        mr.reload
        mr
      end

      def rendered_ui_merge_head_file
        ui_merge_request.reset
        ui_merge_request.merge_head_diff.diffs.diff_files.find { |file| file.new_path == ui_path }
      end

      def rendered_ui_line_codes
        file = rendered_ui_merge_head_file

        file.diff_lines.filter_map { |line| file.line_code(line) }
      end

      def advance_target_above_the_comment!
        project.repository.update_file(
          user, ui_path,
          "# frozen_string_literal: true\n# generated header\n\ndef add(a, b)\n  a + b\nend\n",
          message: 'target prepends header', branch_name: 'ui-shift-target')

        MergeRequests::MergeToRefService.new(project: project, current_user: user).execute(ui_merge_request)
        MergeRequests::ReloadMergeHeadDiffService.new(ui_merge_request).execute
        ui_merge_request.reset
      end

      it 'retraces the draft note once the target branch advances', :aggregate_failures do
        merge_head_file = rendered_ui_merge_head_file
        sum_line = merge_head_file.diff_lines.find { |line| line.added? && line.text.include?('def sum') }.new_pos
        draft = create(:draft_note_on_text_diff, merge_request: ui_merge_request, author: user,
          path: ui_path, line_number: sum_line, diff_refs: ui_merge_request.merge_head_diff.diff_refs)

        expect(draft.original_position.diff_refs).not_to eq(ui_merge_request.diff_refs)
        expect(draft.position.diff_refs).to eq(ui_merge_request.diff_refs)
        expect(rendered_ui_line_codes).to include(draft.line_code)

        advance_target_above_the_comment!

        expect(rendered_ui_line_codes).not_to include(draft.line_code)

        described_class.new(ui_merge_request, [draft]).execute

        expect(rendered_ui_line_codes).to include(draft.line_code)
        expect(draft.merge_head_position).to be_present
      end
    end

    # An earlier-version note update_position could bring forward is retraced from `position`, its place on the
    # current MR diff, which is what the Changes page renders. original_position still serves the superseded version.
    context 'when only the normalised position targets the current MR diff' do
      it 'retraces the draft note from its normalised position', :aggregate_failures do
        earlier_version_draft = create(:draft_note_on_text_diff, merge_request: merge_request,
          author: user, path: path, line_number: source_sum_line, diff_refs: earlier_refs)

        expect(earlier_version_draft.original_position.diff_refs).to eq(earlier_refs)
        expect(earlier_version_draft.position.diff_refs).to eq(merge_request.diff_refs)

        described_class.new(merge_request, [earlier_version_draft]).execute

        expect(rendered_line_codes).to include(earlier_version_draft.line_code)
      end
    end
  end
end
