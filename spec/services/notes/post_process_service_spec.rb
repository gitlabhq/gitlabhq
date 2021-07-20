# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Notes::PostProcessService do
  let(:project) { create(:project) }
  let(:issue) { create(:issue, project: project) }
  let(:user) { create(:user) }

  describe '#execute' do
    before do
      project.add_maintainer(user)
      note_opts = {
        note: 'Awesome comment',
        noteable_type: 'Issue',
        noteable_id: issue.id
      }

      @note = Notes::CreateService.new(project, user, note_opts).execute
    end

    it do
      expect(project).to receive(:execute_hooks)
      expect(project).to receive(:execute_integrations)

      described_class.new(@note).execute
    end

    context 'with a confidential issue' do
      let(:issue) { create(:issue, :confidential, project: project) }

      it "doesn't call note hooks/integrations" do
        expect(project).not_to receive(:execute_hooks).with(anything, :note_hooks)
        expect(project).not_to receive(:execute_integrations).with(anything, :note_hooks)

        described_class.new(@note).execute
      end

      it "calls confidential-note hooks/integrations" do
        expect(project).to receive(:execute_hooks).with(anything, :confidential_note_hooks)
        expect(project).to receive(:execute_integrations).with(anything, :confidential_note_hooks)

        described_class.new(@note).execute
      end
    end

    context 'when the noteable is a design' do
      let_it_be(:noteable) { create(:design, :with_file) }
      let_it_be(:discussion_note) { create_note }

      subject { described_class.new(note).execute }

      def create_note(in_reply_to: nil)
        create(:diff_note_on_design, noteable: noteable, in_reply_to: in_reply_to)
      end

      context 'when the note is the start of a new discussion' do
        let(:note) { discussion_note }

        it 'creates a new system note' do
          expect { subject }.to change { Note.system.count }.by(1)
        end
      end

      context 'when the note is a reply within a discussion' do
        let_it_be(:note) { create_note(in_reply_to: discussion_note) }

        it 'does not create a new system note' do
          expect { subject }.not_to change { Note.system.count }
        end
      end
    end
  end
end
