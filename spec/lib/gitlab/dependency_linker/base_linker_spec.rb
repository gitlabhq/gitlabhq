# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::DependencyLinker::BaseLinker do
  let(:linker_class) do
    Class.new(described_class) do
      def link_dependencies
        link_regex(%r{^(?<name>https?://[^ ]+)}, &:itself)
      end
    end
  end

  let(:plain_content) do
    <<~CONTENT
      http://\\njavascript:alert(1)
      https://gitlab.com/gitlab-org/gitlab
    CONTENT
  end

  let(:highlighted_content) do
    <<~CONTENT
      <span><span>http://</span><span>\\n</span><span>javascript:alert(1)</span></span>
      <span><span>https://gitlab.com/gitlab-org/gitlab</span></span>
    CONTENT
  end

  let(:linker) { linker_class.new(plain_content, highlighted_content) }

  describe '#link' do
    subject { linker.link }

    it 'only converts valid links' do
      expect(subject).to eq(
        <<~CONTENT
          <span><span>#{link('http://', url: nil)}</span><span>#{link('\n', url: nil)}</span><span>#{link('javascript:alert(1)', url: nil)}</span></span>
          <span><span>#{link('https://gitlab.com/gitlab-org/gitlab')}</span></span>
        CONTENT
      )
    end
  end

  def link(text, url: text)
    attrs = [
      'rel="nofollow noreferrer noopener"',
      'target="_blank"'
    ]

    attrs.unshift(%(href="#{url}")) if url

    %(<a #{attrs.join(' ')}>#{text}</a>)
  end
end
