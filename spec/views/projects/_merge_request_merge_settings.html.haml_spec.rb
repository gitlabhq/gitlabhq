require 'spec_helper'

describe 'projects/_merge_request_merge_settings' do
  let(:project) { create(:project) }
  let (:form) { double() }

  before do
    allow(form).to receive_messages(label: nil, check_box: nil)
  end

  it 'shows OMIPS checkbox when pipelines are disabled' do
    allow(project).to receive(:builds_enabled?) { false }

    render partial: 'projects/merge_request_merge_settings', locals: { form: form }

    expect(rendered).to have_selector('.omips')
  end

  it 'shows OMIPS checkbox when pipelines are enabled' do
    allow(project).to receive(:builds_enabled?) { true }

    render partial: 'projects/merge_request_merge_settings', locals: { form: form }

    expect(rendered).to have_selector('.omips')
  end
end
