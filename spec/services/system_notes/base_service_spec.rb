# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SystemNotes::BaseService, feature_category: :groups_and_projects do
  let(:noteable) { double }
  let(:project) { build(:project) }
  let(:author) { build(:user) }
  let(:container) { project }
  let(:base_service) { described_class.new(noteable: noteable, container: container, author: author) }

  describe '#noteable' do
    subject { base_service.noteable }

    it { is_expected.to eq(noteable) }

    it 'returns nil if no arguments are given' do
      instance = described_class.new
      expect(instance.noteable).to be_nil
    end
  end

  describe '#author' do
    subject { base_service.author }

    it { is_expected.to eq(author) }

    it 'returns nil if no arguments are given' do
      instance = described_class.new
      expect(instance.author).to be_nil
    end
  end

  describe '#create_note' do
    let_it_be(:project) { create(:project) }
    let_it_be(:author) { create(:user) }
    let_it_be(:noteable, refind: true) { create(:issue, project: project) }

    let(:service) { described_class.new(noteable: noteable, container: project, author: author) }
    let(:note_summary) { NoteSummary.new(noteable, project, author, 'added 1 commit', action: 'commit') }

    context 'when the note is persisted' do
      it 'returns the note without tracking an exception', :aggregate_failures do
        expect(Gitlab::ErrorTracking).not_to receive(:track_exception)

        expect(service.send(:create_note, note_summary)).to be_persisted
      end
    end

    context 'when the note is not persisted' do
      let(:unpersisted_note) { build(:note, noteable: noteable, project: project, author: author) }

      before do
        allow(Note).to receive(:create).and_return(unpersisted_note)
      end

      it 'tracks the failure with the note context', :aggregate_failures do
        expect(Gitlab::ErrorTracking).to receive(:track_exception) do |exception, extra|
          expect(exception).to be_a(described_class::UnpersistedSystemNoteError)
          expect(exception.message).to eq('System note was not persisted')
          expect(extra).to include(
            noteable_type: 'Issue',
            noteable_id: noteable.id,
            commit_id: nil,
            note_action: 'commit',
            note_errors: [],
            note_bytesize: unpersisted_note.note.bytesize
          )
        end

        service.send(:create_note, note_summary)
      end

      it 'returns the unpersisted note' do
        allow(Gitlab::ErrorTracking).to receive(:track_exception)

        expect(service.send(:create_note, note_summary)).to eq(unpersisted_note)
      end

      context 'when the note is for a commit' do
        let(:unpersisted_note) { build(:note, :on_commit, project: project, author: author) }

        it 'identifies the noteable by its SHA', :aggregate_failures do
          expect(Gitlab::ErrorTracking).to receive(:track_exception) do |_exception, extra|
            expect(extra).to include(
              noteable_type: 'Commit',
              noteable_id: nil,
              commit_id: unpersisted_note.commit_id
            )
          end

          service.send(:create_note, note_summary)
        end
      end

      context 'when the note has validation errors' do
        before do
          unpersisted_note.errors.add(:note, 'is invalid')
        end

        it 'includes them in the tracked context' do
          expect(Gitlab::ErrorTracking).to receive(:track_exception) do |_exception, extra|
            expect(extra).to include(note_errors: ['Note is invalid'])
          end

          service.send(:create_note, note_summary)
        end
      end
    end
  end

  describe '#container' do
    using RSpec::Parameterized::TableSyntax

    let(:project) { build(:project) }
    let(:project_namespace) { build(:project_namespace, project: project) }
    let(:group) { build(:group) }
    let(:user_namespace) { build(:user_namespace) }

    where(:container, :expected_container, :expected_project, :expected_group) do
      nil                     | nil                     | nil           | nil
      ref(:project)           | ref(:project)           | ref(:project) | nil
      ref(:project_namespace) | ref(:project_namespace) | ref(:project) | nil
      ref(:group)             | ref(:group)             | nil           | ref(:group)
      ref(:user_namespace)    | ref(:user_namespace)    | nil           | nil
    end

    with_them do
      it 'expects correct container type' do
        expect(base_service.container).to eq(expected_container)
        expect(base_service.project).to eq(expected_project)
        expect(base_service.group).to eq(expected_group)
      end
    end
  end
end
