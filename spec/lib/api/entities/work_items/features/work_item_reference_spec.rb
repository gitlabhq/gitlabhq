# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::WorkItems::Features::WorkItemReference, feature_category: :team_planning do
  let_it_be(:work_item) { create(:work_item) }

  subject(:representation) { described_class.new(work_item).as_json }

  it 'exposes the expected fields' do
    expect(representation).to include(
      id: work_item.id,
      global_id: work_item.to_gid.to_s,
      iid: work_item.iid,
      title: work_item.title,
      state: work_item.state,
      confidential: work_item.confidential,
      reference: work_item.to_reference(full: true),
      web_url: Gitlab::UrlBuilder.build(work_item),
      web_path: Gitlab::UrlBuilder.build(work_item, only_path: true)
    )
    expect(representation[:work_item_type]).to include(id: work_item.work_item_type.id)
  end
end
