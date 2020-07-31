# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a subscribeable graphql resource' do
  let(:project) { resource.project }
  let_it_be(:user) { create(:user) }

  subject(:mutation) { described_class.new(object: nil, context: { current_user: user }, field: nil) }

  specify { expect(described_class).to require_graphql_authorizations(permission_name) }

  describe '#resolve' do
    let(:subscribe) { true }
    let(:mutated_resource) { subject[resource.class.name.underscore.to_sym] }

    subject { mutation.resolve(project_path: resource.project.full_path, iid: resource.iid, subscribed_state: subscribe) }

    it 'raises an error if the resource is not accessible to the user' do
      expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
    end

    context 'when the user can update the resource' do
      before do
        resource.project.add_developer(user)
      end

      it 'subscribes to the resource' do
        expect(mutated_resource).to eq(resource)
        expect(mutated_resource.subscribed?(user, project)).to eq(true)
        expect(subject[:errors]).to be_empty
      end

      context 'when passing subscribe as false' do
        let(:subscribe) { false }

        it 'unsubscribes from the discussion' do
          resource.subscribe(user, project)

          expect(mutated_resource.subscribed?(user, project)).to eq(false)
        end
      end
    end
  end
end
