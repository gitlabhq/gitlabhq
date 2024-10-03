# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'members/access_denied_mailer/email.html.haml', feature_category: :groups_and_projects do
  let(:source_hidden?) { false }
  let(:member_source) { build(:group) }

  before do
    allow(view).to receive(:source_hidden?).and_return(source_hidden?)
    allow(view).to receive(:member_source).and_return(member_source)
  end

  subject { render && rendered }

  context 'when source is not hidden' do
    it { is_expected.not_to have_text('Hidden') }
    it { is_expected.to have_link(member_source.human_name, href: member_source.web_url) }
  end

  context 'when source is hidden' do
    let(:source_hidden?) { true }

    it { is_expected.to have_text('Hidden') }
    it { is_expected.not_to have_link(member_source.human_name) }
  end
end
