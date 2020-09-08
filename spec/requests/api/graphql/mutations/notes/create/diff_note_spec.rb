# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding a DiffNote' do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }
  let(:noteable) { create(:merge_request, source_project: project, target_project: project) }
  let(:project) { create(:project, :repository) }
  let(:diff_refs) { noteable.diff_refs }
  let(:mutation) do
    variables = {
      noteable_id: GitlabSchema.id_from_object(noteable).to_s,
      body: 'Body text',
      position: {
        paths: {
          old_path: 'files/ruby/popen.rb',
          new_path: 'files/ruby/popen2.rb'
        },
        new_line: 14,
        base_sha: diff_refs.base_sha,
        head_sha: diff_refs.head_sha,
        start_sha: diff_refs.start_sha
      }
    }

    graphql_mutation(:create_diff_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:create_diff_note)
  end

  it_behaves_like 'a Note mutation when the user does not have permission'

  context 'when the user has permission' do
    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a Note mutation that creates a Note'

    it_behaves_like 'a Note mutation when there are active record validation errors', model: DiffNote

    context do
      let(:diff_refs) { build(:commit).diff_refs } # Allow fake diff refs so arguments are valid

      it_behaves_like 'a Note mutation when the given resource id is not for a Noteable'
    end

    it 'returns the note with the correct position' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq('Body text')
      mutation_position_response = mutation_response['note']['position']
      expect(mutation_position_response['positionType']).to eq('text')
      expect(mutation_position_response['filePath']).to eq('files/ruby/popen2.rb')
      expect(mutation_position_response['oldPath']).to eq('files/ruby/popen.rb')
      expect(mutation_position_response['newPath']).to eq('files/ruby/popen2.rb')
      expect(mutation_position_response['newLine']).to eq(14)
    end
  end
end
