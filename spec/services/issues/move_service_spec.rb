require 'spec_helper'

describe Issues::MoveService, services: true do
  let(:user) { create(:user) }
  let(:title) { 'Some issue' }
  let(:description) { 'Some issue description' }
  let(:old_issue) { create(:issue, title: title, description: description) }
  let(:old_project) { old_issue.project }
  let(:new_project) { create(:project) }
  let(:move_service) { described_class.new(old_project, user, move_params, old_issue) }

  shared_context 'issue move requested' do
    let(:move_params) { { 'move_to_project_id' => new_project.id } }
  end

  shared_context 'user can move issue' do
    before do
      old_project.team << [user, :master]
      new_project.team << [user, :master]
    end
  end
    
  context 'issue movable' do
    include_context 'issue move requested'
    include_context 'user can move issue'

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
          note_params = { noteable: old_issue, project: old_project, author: user}
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

  context 'issue move not requested' do
    let(:move_params) { {} }

    describe '#move?' do
      subject { move_service.move? }

      context 'user do not have permissions to move issue' do
        it { is_expected.to be_falsey }
      end

      context 'user has permissions to move issue' do
        include_context 'user can move issue'
        it { is_expected.to be_falsey }
      end
    end
  end


  describe 'move permissions' do
    include_context 'issue move requested'

    describe '#move?' do
      subject { move_service.move? }

      context 'user is master in both projects' do
        include_context 'user can move issue'
        it { is_expected.to be_truthy }
      end

      context 'user is master only in new project' do
        before { new_project.team << [user, :master] }
        it { is_expected.to be_falsey }
      end

      context 'user is master only in old project' do
        before { old_project.team << [user, :master] }
        it { is_expected.to be_falsey }
      end

      context 'user is master in one project and developer in another' do
        before do
          new_project.team << [user, :developer]
          old_project.team << [user, :master]
        end

        it { is_expected.to be_falsey }
      end
    end
  end
end
