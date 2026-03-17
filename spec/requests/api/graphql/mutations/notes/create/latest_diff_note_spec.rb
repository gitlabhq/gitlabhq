# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding a LatestDiffNote', feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let_it_be(:project) { create(:project, :repository) }
  let(:noteable) { create(:merge_request, source_project: project, target_project: project) }
  let(:diff_refs) { noteable.diff_refs }
  let(:file_path) { 'files/ruby/popen.rb' }
  let(:body) { 'Body text' }

  let(:variables) do
    {
      noteable_id: GitlabSchema.id_from_object(noteable).to_s,
      body: body,
      file_path: file_path,
      new_line: 14,
      head_sha: diff_refs.head_sha
    }
  end

  let(:mutation) { graphql_mutation(:create_latest_diff_note, variables) }

  def mutation_response
    graphql_mutation_response(:create_latest_diff_note)
  end

  it_behaves_like 'a Note mutation when the user does not have permission'

  context 'when the user has permission' do
    before_all do
      project.add_developer(current_user)
    end

    it_behaves_like 'a Note mutation that creates a Note'

    it 'returns the note with the correct position' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq('Body text')

      position_response = mutation_response['note']['position']
      expect(position_response['positionType']).to eq('text')
      expect(position_response['filePath']).to eq(file_path)
      expect(position_response['newLine']).to eq(14)
      expect(position_response['oldPath']).to eq('files/ruby/popen.rb')
      expect(position_response['newPath']).to eq('files/ruby/popen.rb')
    end

    it 'resolves SHAs from the merge request diff' do
      post_graphql_mutation(mutation, current_user: current_user)

      note = Note.last
      expect(note.position.base_sha).to eq(diff_refs.base_sha)
      expect(note.position.start_sha).to eq(diff_refs.start_sha)
      expect(note.position.head_sha).to eq(diff_refs.head_sha)
    end

    context 'with old_line' do
      let(:variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: body,
          file_path: file_path,
          old_line: 9,
          head_sha: diff_refs.head_sha
        }
      end

      it_behaves_like 'a Note mutation that creates a Note'

      it 'creates a note on the old side' do
        post_graphql_mutation(mutation, current_user: current_user)

        position_response = mutation_response['note']['position']
        expect(position_response['oldLine']).to eq(9)
      end
    end

    context 'without any line arguments' do
      let(:variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: body,
          file_path: file_path,
          head_sha: diff_refs.head_sha
        }
      end

      it_behaves_like 'a Note mutation that does not create a Note'
    end

    context 'with an invalid file_path' do
      let(:variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: body,
          file_path: 'nonexistent/file.rb',
          new_line: 1,
          head_sha: diff_refs.head_sha
        }
      end

      it_behaves_like 'a Note mutation that does not create a Note'
    end

    context 'with /label quick action' do
      let_it_be(:label) { create(:label, title: 'bug') }

      let(:body) { "Body text\n/label ~bug" }

      before_all do
        label.project.add_developer(current_user)
      end

      before do
        noteable.project.labels << label
      end

      it 'creates the note and applies the label' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['note']['body']).to eq('Body text')
        expect(noteable.reload.label_ids).to include(label.id)
      end
    end

    context 'with an internal note' do
      let(:variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: body,
          file_path: file_path,
          new_line: 14,
          internal: true,
          head_sha: diff_refs.head_sha
        }
      end

      it 'returns an error because DiffNotes do not support internal/confidential' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['errors']).to include('Confidential can not be set for this type of note')
      end
    end

    it_behaves_like 'a Note mutation when there are active record validation errors', model: DiffNote

    context 'with a different file in the diff' do
      let(:file_path) { 'files/ruby/regex.rb' }

      let(:variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: body,
          file_path: file_path,
          new_line: 22,
          head_sha: diff_refs.head_sha
        }
      end

      it 'creates a note on the specified file' do
        post_graphql_mutation(mutation, current_user: current_user)

        position_response = mutation_response['note']['position']
        expect(position_response['filePath']).to eq('files/ruby/regex.rb')
        expect(position_response['positionType']).to eq('text')
      end
    end

    context 'with a stale head_sha' do
      let(:variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: body,
          file_path: file_path,
          new_line: 14,
          head_sha: 'outdated_sha'
        }
      end

      it_behaves_like 'a Note mutation that does not create a Note'
    end

    context 'when comparing with the existing CreateDiffNote mutation' do
      let(:old_mutation_variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: 'parity test',
          position: {
            paths: {
              old_path: 'files/ruby/popen.rb',
              new_path: 'files/ruby/popen.rb'
            },
            base_sha: diff_refs.base_sha,
            head_sha: diff_refs.head_sha,
            start_sha: diff_refs.start_sha,
            new_line: 14
          }
        }
      end

      let(:new_mutation_variables) do
        {
          noteable_id: GitlabSchema.id_from_object(noteable).to_s,
          body: 'parity test',
          file_path: file_path,
          new_line: 14,
          head_sha: diff_refs.head_sha
        }
      end

      it 'produces notes with identical positions' do
        old_mutation = graphql_mutation(:create_diff_note, old_mutation_variables)
        post_graphql_mutation(old_mutation, current_user: current_user)
        old_note = Note.last

        new_mutation = graphql_mutation(:create_latest_diff_note, new_mutation_variables)
        post_graphql_mutation(new_mutation, current_user: current_user)
        new_note = Note.last

        expect(new_note.position.position_type).to eq(old_note.position.position_type)
        expect(new_note.position.file_path).to eq(old_note.position.file_path)
        expect(new_note.position.old_path).to eq(old_note.position.old_path)
        expect(new_note.position.new_path).to eq(old_note.position.new_path)
        expect(new_note.position.new_line).to eq(old_note.position.new_line)
        expect(new_note.position.old_line).to eq(old_note.position.old_line)
        expect(new_note.position.base_sha).to eq(old_note.position.base_sha)
        expect(new_note.position.start_sha).to eq(old_note.position.start_sha)
        expect(new_note.position.head_sha).to eq(old_note.position.head_sha)
      end
    end
  end
end
