# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Adding an image DiffNote' do
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
          old_path: 'files/images/any_image.png',
          new_path: 'files/images/any_image2.png'
        },
        width: 100,
        height: 200,
        x: 1,
        y: 2,
        base_sha: diff_refs.base_sha,
        head_sha: diff_refs.head_sha,
        start_sha: diff_refs.start_sha
      }
    }

    graphql_mutation(:create_image_diff_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:create_image_diff_note)
  end

  it_behaves_like 'a Note mutation when the user does not have permission'

  context 'when the user has permission' do
    before do
      project.add_developer(current_user)
    end

    it_behaves_like 'a Note mutation that creates a Note'

    it_behaves_like 'a Note mutation when there are active record validation errors', model: DiffNote

    it_behaves_like 'a Note mutation when there are rate limit validation errors'

    context do
      let(:diff_refs) { build(:commit).diff_refs } # Allow fake diff refs so arguments are valid

      it_behaves_like 'a Note mutation when the given resource id is not for a Noteable'
    end

    it 'returns the note with the correct position' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']['body']).to eq('Body text')
      mutation_position_response = mutation_response['note']['position']
      expect(mutation_position_response['filePath']).to eq('files/images/any_image2.png')
      expect(mutation_position_response['oldPath']).to eq('files/images/any_image.png')
      expect(mutation_position_response['newPath']).to eq('files/images/any_image2.png')
      expect(mutation_position_response['positionType']).to eq('image')
      expect(mutation_position_response['width']).to eq(100)
      expect(mutation_position_response['height']).to eq(200)
      expect(mutation_position_response['x']).to eq(1)
      expect(mutation_position_response['y']).to eq(2)
    end
  end
end
