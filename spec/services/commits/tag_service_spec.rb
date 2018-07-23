require 'spec_helper'

describe Commits::TagService do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let(:commit) { project.commit }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    let(:service) { described_class.new(project, user, opts) }

    shared_examples 'tagging fails' do
      it 'returns nil' do
        tagged_commit = service.execute(commit)

        expect(tagged_commit).to be_nil
      end

      it 'does not add a system note' do
        service.execute(commit)

        description_notes = find_notes('tag')
        expect(description_notes).to be_empty
      end
    end

    def find_notes(action)
      commit
        .notes
        .joins(:system_note_metadata)
        .where(system_note_metadata: { action: action })
    end

    context 'valid params' do
      let(:opts) do
        {
          tag_name: 'v1.2.3',
          tag_message: 'Release'
        }
      end

      def find_notes(action)
        commit
          .notes
          .joins(:system_note_metadata)
          .where(system_note_metadata: { action: action })
      end

      context 'when tagging succeeds' do
        it 'returns the commit' do
          tagged_commit = service.execute(commit)

          expect(tagged_commit).to eq(commit)
        end

        it 'adds a system note' do
          service.execute(commit)

          description_notes = find_notes('tag')
          expect(description_notes.length).to eq(1)
        end
      end

      context 'when tagging fails' do
        before do
          tag_stub = instance_double(Tags::CreateService)
          allow(Tags::CreateService).to receive(:new).and_return(tag_stub)
          allow(tag_stub).to receive(:execute).and_return({ status: :error })
        end

        include_examples 'tagging fails'
      end
    end

    context 'invalid params' do
      let(:opts) do
        {}
      end

      include_examples 'tagging fails'
    end
  end
end
