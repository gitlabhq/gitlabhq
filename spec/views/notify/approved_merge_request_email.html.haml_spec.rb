# frozen_string_literal: true

require 'spec_helper'
require 'email_spec'

RSpec.describe 'notify/approved_merge_request_email.html.haml' do
  let(:user) { create(:user) }
  let(:merge_request) { create(:merge_request) }
  let(:group) { create(:group) }
  let(:project) { create(:project, group: group) }

  before do
    allow(view).to receive(:message) { instance_double(Mail::Message, subject: 'Subject') }
    assign(:project, project)
    assign(:approved_by, user)
    assign(:merge_request, merge_request)
  end

  it 'contains approval information' do
    render

    expect(rendered).to have_content(merge_request.to_reference.to_s)
    expect(rendered).to have_content("was approved by")
    expect(rendered).to have_content(user.name.to_s)
  end
end
