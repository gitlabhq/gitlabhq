# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MarkdownCache::RefreshWorker, feature_category: :markdown do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, :with_namespace) }

  let(:cache_version) { Gitlab::MarkdownCache::CACHE_COMMONMARK_VERSION_SHIFTED }

  let(:note) do
    create(:note_on_issue, project: project, note: "hey @#{user.username}").tap do |note|
      note.update_columns(note_html: nil, cached_markdown_version: nil)
      IssueUserMention.where(note_id: note.id).delete_all
    end
  end

  let(:job_args) { [note.class.name, note.id] }

  subject(:perform) { described_class.new.perform(*job_args) }

  it_behaves_like 'an idempotent worker' do
    it 'persists the refreshed HTML and mentions' do
      perform_idempotent_work

      expect(note.reload.cached_markdown_version).to eq(cache_version)
      expect(note.note_html).to be_present
      expect(IssueUserMention.where(note_id: note.id).pick(:mentioned_users_ids)).to eq([user.id])
    end
  end

  describe 'database health deferral' do
    let(:health_check_block) { described_class.database_health_check_attrs[:block] }

    it 'checks the table of the job class in its own schema' do
      expect(health_check_block.call(job_args, :gitlab_main, [])).to eq([:gitlab_main_org, ['notes']])
    end

    it 'checks no tables when the job class does not exist' do
      expect(health_check_block.call(['NoSuchMarkdownModel', 1], :gitlab_main, [])).to eq([:gitlab_main, []])
    end
  end

  context 'when the record is already current' do
    before do
      note.refresh_markdown_cache!
    end

    it 'does not render it again' do
      expect(Banzai::Renderer).not_to receive(:cacheless_render_field)

      perform
    end
  end

  context 'when the record no longer exists' do
    let(:job_args) { ['Note', non_existing_record_id] }

    it 'does nothing' do
      expect { perform }.not_to raise_error
    end
  end

  context 'when the class does not exist' do
    let(:job_args) { ['NoSuchMarkdownModel', non_existing_record_id] }

    it 'does nothing' do
      expect { perform }.not_to raise_error
    end
  end
end
