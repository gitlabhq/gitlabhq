# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssueBoardEntity do
  include Gitlab::Routing.url_helpers

  let(:project) { build_stubbed(:project) }
  let(:resource) { build_stubbed(:issue, project: project) }
  let(:user) { build_stubbed(:user) }
  let(:milestone) { build_stubbed(:milestone, project: project) }
  let(:label) { build_stubbed(:label, project: project, title: 'Test Label') }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'has basic attributes' do
    expect(subject).to include(
      :id, :iid, :title, :confidential, :due_date, :project_id, :relative_position,
      :labels, :assignees, project: hash_including(:id, :path, :path_with_namespace)
    )
  end

  it 'has path and endpoints' do
    expect(subject).to include(
      :reference_path, :real_path, :issue_sidebar_endpoint,
      :toggle_subscription_endpoint, :assignable_labels_endpoint
    )
  end

  it 'has milestone attributes' do
    resource.milestone = milestone

    expect(subject).to include(milestone: hash_including(:id, :title))
  end

  it 'has assignee attributes' do
    allow(resource).to receive(:assignees).and_return([user])

    expect(subject).to include(assignees: array_including(hash_including(:id, :name, :username, :avatar_url)))
  end

  it 'has label attributes' do
    allow(resource).to receive(:labels).and_return([label])

    expect(subject).to include(labels: array_including(hash_including(:id, :title, :color, :description, :text_color, :priority)))
  end

  describe 'type' do
    it 'has an issue type' do
      expect(subject[:type]).to eq('ISSUE')
    end
  end

  describe 'real_path' do
    it 'has an issue path' do
      expect(subject[:real_path]).to eq(::Gitlab::UrlBuilder.instance.issue_path(resource))
    end
  end
end
