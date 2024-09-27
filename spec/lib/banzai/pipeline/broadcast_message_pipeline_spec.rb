# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Pipeline::BroadcastMessagePipeline, feature_category: :markdown do
  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }

  before do
    stub_commonmark_sourcepos_disabled
  end

  subject { described_class.to_html(exp, project: project) }

  it_behaves_like 'sanitize pipeline'

  context "allows `a` elements" do
    let(:exp) { "<a>Link</a>" }

    it { is_expected.to eq("<p>#{exp}</p>") }
  end

  context "allows `br` elements" do
    let(:exp) { "Hello<br>World" }

    it { is_expected.to eq("<p>#{exp}</p>") }
  end
end
