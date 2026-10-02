# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestBasicEntity, feature_category: :code_review_workflow do
  let(:user) { build(:user) }
  let(:request) { EntityRequest.new(current_user: user) }
  let(:resource) { build(:merge_request, params) }
  let(:params) { {} }

  subject do
    described_class.new(resource, request: request).as_json
  end

  it 'has public_merge_status as merge_status' do
    expect(resource).to receive(:public_merge_status).and_return('checking')

    expect(subject[:merge_status]).to eq 'checking'
  end

  describe '#title_html' do
    let(:params) { { title: 'Title with `code`' } }

    it 'renders the title as markdown' do
      expect(subject[:title_html]).to include('<code>code</code>')
    end

    it 'passes the current user to the markdown renderer' do
      expect_next_instance_of(described_class) do |entity|
        expect(entity).to receive(:markdown_field).with(resource, :title, current_user: user)
      end

      subject
    end

    context 'without a request' do
      let(:request) { nil }

      it 'renders the title as markdown without a current user' do
        expect(subject[:title_html]).to include('<code>code</code>')
      end
    end
  end

  describe '#reviewers' do
    let(:params) { { reviewers: [reviewer] } }
    let(:reviewer) { build(:user) }

    it 'contains reviewers attributes' do
      expect(subject[:reviewers].count).to be 1
      expect(subject[:reviewers].first.keys).to include(
        :id, :name, :username, :state, :avatar_url, :web_url
      )
    end
  end
end
