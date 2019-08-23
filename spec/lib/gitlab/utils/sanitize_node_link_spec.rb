# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Utils::SanitizeNodeLink do
  let(:klass) do
    struct = Struct.new(:value)
    struct.include(described_class)

    struct
  end

  subject(:object) { klass.new(:value) }

  invalid_schemes = [
    "javascript:",
    "JaVaScRiPt:",
    "\u0001java\u0003script:",
    "javascript    :",
    "javascript:    ",
    "javascript    :   ",
    ":javascript:",
    "javascript&#58;",
    "javascript&#0058;",
    " &#14;  javascript:"
  ]

  invalid_schemes.each do |scheme|
    context "with the scheme: #{scheme}" do
      describe "#remove_unsafe_links" do
        tags = {
          a: {
            doc: HTML::Pipeline.parse("<a href='#{scheme}alert(1);'>foo</a>"),
            attr: "href",
            node_to_check: -> (doc) { doc.children.first }
          },
          img: {
            doc: HTML::Pipeline.parse("<img src='#{scheme}alert(1);'>"),
            attr: "src",
            node_to_check: -> (doc) { doc.children.first }
          },
          video: {
            doc: HTML::Pipeline.parse("<video><source src='#{scheme}alert(1);'></video>"),
            attr: "src",
            node_to_check: -> (doc) { doc.children.first.children.filter("source").first }
          }
        }

        tags.each do |tag, opts|
          context "<#{tag}> tags" do
            it "removes the unsafe link" do
              node = opts[:node_to_check].call(opts[:doc])

              expect { object.remove_unsafe_links({ node: node }, remove_invalid_links: true) }
                .to change { node[opts[:attr]] }

              expect(node[opts[:attr]]).to be_blank
            end
          end
        end
      end

      describe "#safe_protocol?" do
        let(:doc) { HTML::Pipeline.parse("<a href='#{scheme}alert(1);'>foo</a>") }
        let(:node) { doc.children.first }
        let(:uri) { Addressable::URI.parse(node['href'])}

        it "returns false" do
          expect(object.safe_protocol?(scheme)).to be_falsy
        end
      end
    end
  end
end
