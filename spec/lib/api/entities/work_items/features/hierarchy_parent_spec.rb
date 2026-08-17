# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::HierarchyParent, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }

  subject(:representation) { described_class.new(work_item).as_json }

  it 'exposes the fields inherited from WorkItemReference plus namespace' do
    expect(representation).to include(
      id: work_item.id,
      iid: work_item.iid,
      title: work_item.title
    )
    expect(representation[:namespace]).to include(
      id: work_item.namespace_id,
      full_path: work_item.namespace.full_path,
      kind: work_item.namespace.kind
    )
  end
end
