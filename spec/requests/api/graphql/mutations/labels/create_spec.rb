# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Mutations::Labels::Create do
  include GraphqlHelpers

  let_it_be(:current_user) { create(:user) }

  let(:params) do
    {
      'title' => 'foo',
      'description' => 'some description',
      'color' => '#FF0000'
    }
  end

  let(:mutation) { graphql_mutation(:label_create, params.merge(extra_params)) }

  subject { post_graphql_mutation(mutation, current_user: current_user) }

  def mutation_response
    graphql_mutation_response(:label_create)
  end

  shared_examples_for 'labels create mutation' do
    context 'when the user does not have permission to create a label' do
      it_behaves_like 'a mutation that returns a top-level access error'

      it 'does not create the label' do
        expect { subject }.not_to change { Label.count }
      end
    end

    context 'when the user has permission to create a label' do
      before do
        parent.add_developer(current_user)
      end

      context 'when the parent (project_path or group_path) param is given' do
        it 'creates the label' do
          expect { subject }.to change { Label.count }.to(1)

          expect(mutation_response).to include(
            'label' => a_hash_including(params))
        end

        it 'does not create a label when there are errors' do
          label_factory = parent.is_a?(Group) ? :group_label : :label
          create(label_factory, title: 'foo', parent.class.name.underscore.to_sym => parent)

          expect { subject }.not_to change { Label.count }

          expect(mutation_response).to have_key('label')
          expect(mutation_response['label']).to be_nil
          expect(mutation_response['errors'].first).to eq('Title has already been taken')
        end
      end
    end
  end

  context 'when creating a project label' do
    let_it_be(:parent) { create(:project) }

    let(:extra_params) { { project_path: parent.full_path } }

    it_behaves_like 'labels create mutation'
  end

  context 'when creating a group label' do
    let_it_be(:parent) { create(:group) }

    let(:extra_params) { { group_path: parent.full_path } }

    it_behaves_like 'labels create mutation'
  end

  context 'when neither project_path nor group_path param is given' do
    let(:mutation) { graphql_mutation(:label_create, params) }

    it_behaves_like 'a mutation that returns top-level errors',
      errors: ['Exactly one of group_path or project_path arguments is required']

    it 'does not create the label' do
      expect { subject }.not_to change { Label.count }
    end
  end
end
