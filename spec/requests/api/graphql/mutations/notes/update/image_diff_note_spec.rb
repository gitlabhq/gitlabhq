# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Updating an image DiffNote' do
  include GraphqlHelpers
  using RSpec::Parameterized::TableSyntax

  let_it_be(:noteable) { create(:merge_request) }
  let_it_be(:original_body) { 'Original body' }
  let_it_be(:original_position) do
    Gitlab::Diff::Position.new(
      old_path: 'files/images/any_image.png',
      new_path: 'files/images/any_image.png',
      width: 10,
      height: 20,
      x: 1,
      y: 2,
      diff_refs: noteable.diff_refs,
      position_type: 'image'
    )
  end

  let_it_be(:updated_body) { 'Updated body' }
  let_it_be(:updated_width) { 50 }
  let_it_be(:updated_height) { 100 }
  let_it_be(:updated_x) { 5 }
  let_it_be(:updated_y) { 10 }

  let(:updated_position) do
    {
      width: updated_width,
      height: updated_height,
      x: updated_x,
      y: updated_y
    }.compact.presence
  end

  let!(:diff_note) do
    create(:image_diff_note_on_merge_request,
           noteable: noteable,
           project: noteable.project,
           note: original_body,
           position: original_position)
  end

  let(:mutation) do
    variables = {
      id: GitlabSchema.id_from_object(diff_note).to_s,
      body: updated_body
    }

    variables[:position] = updated_position if updated_position

    graphql_mutation(:update_image_diff_note, variables)
  end

  def mutation_response
    graphql_mutation_response(:update_image_diff_note)
  end

  context 'when the user does not have permission' do
    let_it_be(:current_user) { create(:user) }

    it_behaves_like 'a mutation that returns a top-level access error'

    it 'does not update the DiffNote' do
      post_graphql_mutation(mutation, current_user: current_user)

      diff_note.reload

      expect(diff_note).to have_attributes(
        note: original_body,
        position: have_attributes(
          width: original_position.width,
          height: original_position.height,
          x: original_position.x,
          y: original_position.y
        )
      )
    end
  end

  context 'when the user has permission' do
    let(:current_user) { diff_note.author }

    it 'updates the DiffNote' do
      post_graphql_mutation(mutation, current_user: current_user)

      diff_note.reload

      expect(diff_note).to have_attributes(
        note: updated_body,
        position: have_attributes(
          width: updated_width,
          height: updated_height,
          x: updated_x,
          y: updated_y
        )
      )
    end

    it 'returns the updated DiffNote' do
      post_graphql_mutation(mutation, current_user: current_user)

      expect(mutation_response['note']).to include(
        'body' => updated_body,
        'position' => hash_including(
          'width' => updated_width,
          'height' => updated_height,
          'x' => updated_x,
          'y' => updated_y
        )
      )
    end

    describe 'updating single properties at a time' do
      where(:property, :new_value) do
        :body | 'foo'
        :width | 19
        :height | 18
        :x | 17
        :y | 16
      end

      with_them do
        # Properties that will be POSTed:
        let(:updated_body) { value(:body) }
        let(:updated_width) { value(:width) }
        let(:updated_height) { value(:height) }
        let(:updated_x) { value(:x) }
        let(:updated_y) { value(:y) }
        # Expectations of the properties:
        let(:expected_body) { value(:body) || original_body }
        let(:expected_width) { value(:width) || original_position.width }
        let(:expected_height) { value(:height) || original_position.height }
        let(:expected_x) { value(:x) || original_position.x }
        let(:expected_y) { value(:y) || original_position.y }

        def value(prop)
          new_value if property == prop
        end

        it 'updates the DiffNote correctly' do
          post_graphql_mutation(mutation, current_user: current_user)

          diff_note.reload

          expect(diff_note).to have_attributes(
            note: expected_body,
            position: have_attributes(
              width: expected_width,
              height: expected_height,
              x: expected_x,
              y: expected_y
            )
          )
        end
      end

      context 'when position is nil' do
        let(:updated_position) { nil }

        it 'updates the DiffNote correctly' do
          post_graphql_mutation(mutation, current_user: current_user)

          diff_note.reload

          expect(diff_note).to have_attributes(
            note: updated_body,
            position: original_position
          )
        end
      end
    end

    context 'when both body and position args are blank' do
      let(:updated_body) { nil }
      let(:updated_position) { nil }

      it_behaves_like 'a mutation that returns top-level errors', errors: ['body or position arguments are required']
    end

    context 'when the resource is not a Note' do
      let(:diff_note) { note }

      it_behaves_like 'a Note mutation when the given resource id is not for a Note'
    end

    context 'when resource is not a DiffNote on an image' do
      let!(:diff_note) { create(:diff_note_on_merge_request, note: original_body) }

      it_behaves_like 'a mutation that returns top-level errors', errors: ['Resource is not an ImageDiffNote']
    end

    context 'when there are ActiveRecord validation errors' do
      before do
        expect(diff_note).to receive_message_chain(
          :errors,
          :full_messages
        ).and_return(['Error 1', 'Error 2'])

        expect_next_instance_of(Notes::UpdateService) do |service|
          expect(service).to receive(:execute).and_return(diff_note)
        end
      end

      it_behaves_like 'a mutation that returns errors in the response', errors: ['Error 1', 'Error 2']

      it 'does not update the DiffNote' do
        post_graphql_mutation(mutation, current_user: current_user)

        diff_note.reload

        expect(diff_note).to have_attributes(
          note: original_body,
          position: have_attributes(
            width: original_position.width,
            height: original_position.height,
            x: original_position.x,
            y: original_position.y
          )
        )
      end

      it 'returns the DiffNote with its original body' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response['note']).to include(
          'body' => original_body,
          'position' => hash_including(
            'width' => original_position.width,
            'height' => original_position.height,
            'x' => original_position.x,
            'y' => original_position.y
          )
        )
      end
    end

    context 'when body only contains quick actions' do
      let(:updated_body) { '/close' }

      it 'returns a nil note and empty errors' do
        post_graphql_mutation(mutation, current_user: current_user)

        expect(mutation_response).to include(
          'errors' => [],
          'note' => nil
        )
      end
    end
  end
end
