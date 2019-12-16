# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Pipeline::BroadcastMessagePipeline do
  before do
    stub_commonmark_sourcepos_disabled
  end

  subject { described_class.to_html(exp, project: spy) }

  context "allows `a` elements" do
    let(:exp) { "<a>Link</a>" }

    it { is_expected.to eq("<p>#{exp}</p>") }
  end

  context "allows `br` elements" do
    let(:exp) { "Hello<br>World" }

    it { is_expected.to eq("<p>#{exp}</p>") }
  end
end
