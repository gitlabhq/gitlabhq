require 'spec_helper'

describe Banzai::Filter::MarkdownFilter do
  include FilterSpecHelper

  context 'code block' do
    it 'adds language to lang attribute when specified' do
      result = filter("```html\nsome code\n```")

      expect(result).to start_with("\n<pre><code lang=\"html\">")
    end

    it 'does not add language to lang attribute when not specified' do
      result = filter("```\nsome code\n```")

      expect(result).to start_with("\n<pre><code>")
    end
  end
end
