require 'spec_helper'

describe Issues::MoveService, services: true do
  let(:user) { create(:user) }
  let(:title) { 'Some issue' }
  let(:description) { 'Some issue description' }
  let(:old_issue) { create(:issue, title: title, description: description) }
  let(:current_project) { old_issue.project }
  let(:new_project) { create(:project) }
  let(:move_params) { { 'move_to_project_id' => new_project.id } }
  let(:move_service) { described_class.new(current_project, user, move_params, old_issue) }

  before { current_project.team << [user, :master] }

  context 'issue movable' do
    describe '#move?' do
      subject { move_service.move? }
      it { is_expected.to be_truthy }
    end

    describe '#execute' do
      shared_context 'issue move executed' do
        let!(:new_issue) { move_service.execute }
      end

      context 'generic issue' do
        include_context 'issue move executed'

        it 'creates a new issue in a new project' do
          expect(new_issue.project).to eq new_project
        end

        it 'rewrites issue title' do
          expect(new_issue.title).to eq title
        end

        it 'rewrites issue description' do
          expect(new_issue.description).to include description
        end

        it 'adds system note to old issue at the end' do
          expect(old_issue.notes.last.note).to match /^Moved to/
        end

        it 'adds system note to new issue at the end' do
          expect(new_issue.notes.last.note).to match /^Moved from/
        end
      end

      context 'notes exist' do
        let(:note_contents) do
          ['Some system note 1', 'Some comment', 'Some system note 2']
        end

        before do
          note_params = { noteable: old_issue, project: current_project, author: user}
          create(:system_note, note_params.merge(note: note_contents.first))
          create(:note, note_params.merge(note: note_contents.second))
          create(:system_note, note_params.merge(note: note_contents.third))
        end

        include_context 'issue move executed'

        let(:new_notes) { new_issue.notes.order('id ASC').pluck(:note) }

        it 'rewrites existing system notes in valid order' do
          expect(new_notes.first(3)).to eq note_contents
        end

        it 'adds a system note about move after rewritten notes' do
          expect(new_notes.last).to match /^Moved from/
        end
      end
    end
  end

  context 'issue not movable' do
    context 'move not requested' do
      let(:move_params) { {} }

      describe '#move?' do
        subject { move_service.move? }
        it { is_expected.to be_falsey }
      end
    end
  end
end
