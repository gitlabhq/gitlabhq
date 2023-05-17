# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Commits::TagService, feature_category: :source_code_management do
  let(:project) { create(:project, :repository) }
  let(:user) { create(:user) }

  let(:commit) { project.commit }

  before do
    project.add_maintainer(user)
  end

  describe '#execute' do
    let(:service) { described_class.new(project, user, opts) }

    shared_examples 'tag failure' do
      it 'returns a hash with the :error status' do
        result = service.execute(commit)

        expect(result[:status]).to eq(:error)
        expect(result[:message]).to eq(error_message)
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
        it 'returns a hash with the :success status and created tag' do
          result = service.execute(commit)

          expect(result[:status]).to eq(:success)

          tag = result[:tag]
          expect(tag.name).to eq(opts[:tag_name])
          expect(tag.message).to eq(opts[:tag_message])
        end

        it 'adds a system note' do
          service.execute(commit)

          description_notes = find_notes('tag')
          expect(description_notes.length).to eq(1)
        end
      end

      context 'when tagging fails' do
        let(:tag_error) { 'GitLab: You are not allowed to push code to this project.' }

        before do
          tag_stub = instance_double(Tags::CreateService)
          allow(Tags::CreateService).to receive(:new).and_return(tag_stub)
          allow(tag_stub).to receive(:execute).and_return({
            status: :error, message: tag_error
          })
        end

        it_behaves_like 'tag failure' do
          let(:error_message) { tag_error }
        end
      end
    end

    context 'invalid params' do
      let(:opts) do
        {}
      end

      it_behaves_like 'tag failure' do
        let(:error_message) { 'Missing parameter tag_name' }
      end
    end
  end
end
