# frozen_string_literal: true

require 'spec_helper'

describe IssueBoardEntity do
  let(:project)  { create(:project) }
  let(:resource) { create(:issue, project: project) }
  let(:user)     { create(:user) }

  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'has basic attributes' do
    expect(subject).to include(:id, :iid, :title, :confidential, :due_date, :project_id, :relative_position,
                               :project, :labels)
  end

  it 'has path and endpoints' do
    expect(subject).to include(:reference_path, :real_path, :issue_sidebar_endpoint,
                               :toggle_subscription_endpoint, :assignable_labels_endpoint)
  end
end
