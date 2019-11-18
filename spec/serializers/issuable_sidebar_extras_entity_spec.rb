# frozen_string_literal: true

require 'spec_helper'

describe IssuableSidebarExtrasEntity do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }
  let(:resource) { create(:issue, project: project) }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'have subscribe attributes' do
    expect(subject).to include(:participants,
                               :project_emails_disabled,
                               :subscribe_disabled_description,
                               :subscribed,
                               :assignees)
  end
end
