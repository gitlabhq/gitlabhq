# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::MobilePush::SummaryPayload, feature_category: :notifications do
  let_it_be(:user) { create(:user) }
  let_it_be(:project) { create(:project) }

  subject(:payload) { described_class.new(user) }

  it 'carries only the generic copy' do
    expect(payload.title).to be_nil
    expect(payload.subtitle).to be_nil
    expect(payload.thread_id).to be_nil
    expect(payload.body).to eq('You have new to-dos')
    expect(payload.mutable_content?).to be(false)
  end

  it 'exposes the pending to-do count as badge' do
    create_list(:todo, 2, user: user, project: project)

    expect(payload.badge).to eq(2)
  end

  it 'collapses per user' do
    expect(payload.collapse_id).to eq("summary-#{user.id}")
  end

  it 'restricts the gitlab dict to identifiers' do
    expect(payload.gitlab_data).to eq(version: 1, type: 'summary', user_id: user.id)
  end
end
