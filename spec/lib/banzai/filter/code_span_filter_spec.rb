# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::CodeSpanFilter, feature_category: :markdown do
  include FilterSpecHelper

  let(:context) { { pipeline: :issuable_title } }

  where(:input, :output) do
    [
      ["\\`",                        %(`)],
      ["\\\\`oh`",                   %(\\\\<code>oh</code>)],
      ["\\\\\\`oh`",                 %(\\\\`oh`)],
      ["`hello`",                    %(<code>hello</code>)],
      ["hello `worl`!",              %(hello <code>worl</code>!)],
      ["my \\escaped \\` things`\\", %(my \\escaped ` things`\\)],
      ["my \\符\\`号`化`された", %(my \\符`号<code>化</code>された)],
      ["w\\`ao\\",                   %(w`ao\\)],
      ["hm` ` `ok`",                 %(hm<code> </code> <code>ok</code>)]
    ]
  end

  with_them do
    it 'marks up as necessary' do
      doc = filter(input, context)
      expect(doc.to_html).to eq_html output
    end
  end

  it_behaves_like 'a filter timeout' do
    let(:text) { 'text' }
  end
end
