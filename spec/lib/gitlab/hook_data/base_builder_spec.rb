require 'spec_helper'

describe Gitlab::HookData::BaseBuilder do
  describe '#absolute_image_urls' do
    let(:subclass) do
      Class.new(described_class) do
        public :absolute_image_urls
      end
    end

    subject { subclass.new(nil) }

    using RSpec::Parameterized::TableSyntax

    where do
      {
        'relative image URL' => {
          input: '![an image](foo.png)',
          output: "![an image](#{Gitlab.config.gitlab.url}/foo.png)"
        },
        'HTTP URL' => {
          input: '![an image](http://example.com/foo.png)',
          output: '![an image](http://example.com/foo.png)'
        },
        'HTTPS URL' => {
          input: '![an image](https://example.com/foo.png)',
          output: '![an image](https://example.com/foo.png)'
        },
        'protocol-relative URL' => {
          input: '![an image](//example.com/foo.png)',
          output: '![an image](//example.com/foo.png)'
        },
        'URL reference by title' => {
          input: "![foo]\n\n[foo]: foo.png",
          output: "![foo]\n\n[foo]: foo.png"
        },
        'URL reference by label' => {
          input: "![][foo]\n\n[foo]: foo.png",
          output: "![][foo]\n\n[foo]: foo.png"
        },
        'in Markdown inline code block' => {
          input: '`![an image](foo.png)`',
          output: "`![an image](#{Gitlab.config.gitlab.url}/foo.png)`"
        },
        'in HTML tag on the same line' => {
          input: '<p>![an image](foo.png)</p>',
          output: "<p>![an image](#{Gitlab.config.gitlab.url}/foo.png)</p>"
        },
        'in Markdown multi-line code block' => {
          input: "```\n![an image](foo.png)\n```",
          output: "```\n![an image](foo.png)\n```"
        },
        'in HTML tag on different lines' => {
          input: "<p>\n![an image](foo.png)\n</p>",
          output: "<p>\n![an image](foo.png)\n</p>"
        }
      }
    end

    with_them do
      it { expect(subject.absolute_image_urls(input)).to eq(output) }
    end
  end
end
