# frozen_string_literal: true

require 'spec_helper'

RSpec.shared_examples 'a subscribeable not accessible graphql resource' do
  include GraphqlHelpers

  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }
  let(:mutation) { described_class.new(object: nil, context: context, field: nil) }

  subject { mutation.resolve(project_path: resource.project.full_path, iid: resource.iid, subscribed_state: true) }

  it 'raises an error if the resource is not accessible to the user' do
    expect { subject }.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
  end
end

RSpec.shared_examples 'a subscribeable graphql resource' do
  include GraphqlHelpers

  let(:query) { GraphQL::Query.new(empty_schema, document: nil, context: {}, variables: {}) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: { current_user: user }) }
  let(:mutated_resource) { subject[resource.class.name.underscore.to_sym] }
  let(:mutation) { described_class.new(object: nil, context: context, field: nil) }
  let(:subscribe) { true }

  subject { mutation.resolve(project_path: resource.project.full_path, iid: resource.iid, subscribed_state: subscribe) }

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
      expect(subject[:errors]).to be_empty
    end
  end
end
