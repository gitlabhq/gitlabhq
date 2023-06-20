# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::DraftNote, feature_category: :code_review_workflow do
  let_it_be(:entity) { create(:draft_note, :on_discussion) }
  let_it_be(:json) { entity.as_json }

  it 'exposes correct attributes' do
    position = entity.position.to_h.except(:ignore_whitespace_change)

    expect(json["id"]).to eq entity.id
    expect(json["author_id"]).to eq entity.author_id
    expect(json["merge_request_id"]).to eq entity.merge_request_id
    expect(json["resolve_discussion"]).to eq entity.resolve_discussion
    expect(json["discussion_id"]).to eq entity.discussion_id
    expect(json["note"]).to eq entity.note
    expect(json["position"].transform_keys(&:to_sym)).to eq position
  end
end
