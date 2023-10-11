# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'gitlab:external_diffs rake tasks', :silence_stdout do
  before do
    Rake.application.rake_require 'tasks/gitlab/external_diffs'
  end

  describe 'force_object_storage task' do
    it 'forces externally stored merge request diffs to object storage' do
      db = create(:merge_request).merge_request_diff
      file = create(:merge_request).merge_request_diff.tap { |o| o.update_columns(stored_externally: true, external_diff_store: 1) }
      object = create(:merge_request).merge_request_diff.tap { |o| o.update_columns(stored_externally: true, external_diff_store: 2) }

      run_rake_task('gitlab:external_diffs:force_object_storage')

      expect(db.reload).not_to be_stored_externally
      expect(file.reload).to be_stored_externally
      expect(object.reload).to be_stored_externally

      expect(file.external_diff_store).to eq(2)
      expect(object.external_diff_store).to eq(2)
    end

    it 'limits batches according to BATCH_SIZE, START_ID, and END_ID' do
      stub_env('START_ID' => 'foo', 'END_ID' => 'bar', 'BATCH_SIZE' => 'baz')

      expect(MergeRequestDiff).to receive(:in_batches).with(start: 'foo', finish: 'bar', of: 'baz')

      run_rake_task('gitlab:external_diffs:force_object_storage')
    end
  end
end
