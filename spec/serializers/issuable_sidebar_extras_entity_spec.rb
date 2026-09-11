# frozen_string_literal: true

require 'spec_helper'

RSpec.describe IssuableSidebarExtrasEntity do
  let(:user) { create(:user) }
  let_it_be(:project) { create(:project) }
  let(:resource) { create(:issue, project: project) }
  let(:request) { double('request', current_user: user) }

  subject { described_class.new(resource, request: request).as_json }

  it 'have assignee attribute' do
    expect(subject).to include(:assignees)
  end
end
