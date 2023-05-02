# frozen_string_literal: true

require 'fast_spec_helper'
require 'rspec-parameterized'

RSpec.describe Gitlab::Utils::Nokogiri do
  describe '#css_to_xpath' do
    using RSpec::Parameterized::TableSyntax

    where(:css, :xpath) do
      'img'                               | "descendant-or-self::img"
      'a.gfm'                             | "descendant-or-self::a[contains(concat(' ',normalize-space(@class),' '),' gfm ')]"
      'a:not(.gfm)'                       | "descendant-or-self::a[not(contains(concat(' ',normalize-space(@class),' '),' gfm '))]"
      'video, audio'                      | "descendant-or-self::video|descendant-or-self::audio"
      '[data-math-style]'                 | "descendant-or-self::*[@data-math-style]"
      '[data-mermaid-style]'              | "descendant-or-self::*[@data-mermaid-style]"
      '.js-render-metrics'                | "descendant-or-self::*[contains(concat(' ',normalize-space(@class),' '),' js-render-metrics ')]"
      'h1, h2, h3, h4, h5, h6'            | "descendant-or-self::h1|descendant-or-self::h2|descendant-or-self::h3|descendant-or-self::h4|descendant-or-self::h5|descendant-or-self::h6"
      'pre.code.language-math'            | "descendant-or-self::pre[contains(concat(' ',normalize-space(@class),' '),' code ') and contains(concat(' ',normalize-space(@class),' '),' language-math ')]"
      'pre > code[data-canonical-lang="plantuml"]' | "descendant-or-self::pre/code[@data-canonical-lang=\"plantuml\"]"
      'pre[data-canonical-lang="mermaid"] > code'  | "descendant-or-self::pre[@data-canonical-lang=\"mermaid\"]/code"
      'pre.language-suggestion'           | "descendant-or-self::pre[contains(concat(' ',normalize-space(@class),' '),' language-suggestion ')]"
      'pre.language-suggestion > code'    | "descendant-or-self::pre[contains(concat(' ',normalize-space(@class),' '),' language-suggestion ')]/code"
      'a.gfm[data-reference-type="user"]' | "descendant-or-self::a[contains(concat(' ',normalize-space(@class),' '),' gfm ') and @data-reference-type=\"user\"]"
      'a:not(.gfm), img:not(.gfm), video:not(.gfm), audio:not(.gfm)'                        | "descendant-or-self::a[not(contains(concat(' ',normalize-space(@class),' '),' gfm '))]|descendant-or-self::img[not(contains(concat(' ',normalize-space(@class),' '),' gfm '))]|descendant-or-self::video[not(contains(concat(' ',normalize-space(@class),' '),' gfm '))]|descendant-or-self::audio[not(contains(concat(' ',normalize-space(@class),' '),' gfm '))]"
      'pre:not([data-math-style]):not([data-mermaid-style]):not([data-kroki-style]) > code' | "descendant-or-self::pre[not(@data-math-style) and not(@data-mermaid-style) and not(@data-kroki-style)]/code"
    end

    with_them do
      it 'generates the xpath' do
        expect(described_class.css_to_xpath(css)).to eq xpath
      end
    end
  end
end
