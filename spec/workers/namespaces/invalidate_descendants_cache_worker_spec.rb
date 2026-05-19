# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Namespaces::InvalidateDescendantsCacheWorker, feature_category: :groups_and_projects do
  let_it_be(:project) { create(:project) }

  let(:event) do
    ::Projects::ProjectArchivedEvent.new(data: {
      project_id: project.id,
      namespace_id: project.namespace_id,
      root_namespace_id: project.root_namespace.id
    })
  end

  subject(:use_event) { consume_event(subscriber: described_class, event: event) }

  it_behaves_like 'subscribes to event'

  it 'expires the namespace_descendants cache for the namespace' do
    expect(Namespaces::Descendants).to receive(:expire_for).with([project.namespace_id])

    use_event
  end
end
