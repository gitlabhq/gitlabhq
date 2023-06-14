# frozen_string_literal: true

# TODO: change to fast_spec_helper in scope of https://gitlab.com/gitlab-org/gitlab/-/issues/413779
require 'spec_helper'
require 'html/pipeline'
require 'addressable'

RSpec.describe Gitlab::Utils::SanitizeNodeLink do
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

  describe "#remove_unsafe_links" do
    subject { object.remove_unsafe_links(env, remove_invalid_links: true) }

    let(:env) { { node: node } }

    invalid_schemes.each do |scheme|
      context "with the scheme: #{scheme}" do
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
          },
          audio: {
            doc: HTML::Pipeline.parse("<audio><source src='#{scheme}alert(1);'></audio>"),
            attr: "src",
            node_to_check: -> (doc) { doc.children.first.children.filter("source").first }
          }
        }

        tags.each do |tag, opts|
          context "<#{tag}> tags" do
            let(:node) { opts[:node_to_check].call(opts[:doc]) }

            it "removes the unsafe link" do
              expect { subject }.to change { node[opts[:attr]] }

              expect(node[opts[:attr]]).to be_blank
            end
          end
        end
      end
    end

    context 'when URI is valid' do
      let(:doc) { HTML::Pipeline.parse("<a href='http://example.com'>foo</a>") }
      let(:node) { doc.children.first }

      it 'does not remove it' do
        subject

        expect(node[:href]).to eq('http://example.com')
      end
    end

    context 'when URI is invalid' do
      let(:doc) { HTML::Pipeline.parse("<a href='http://example:wrong_port.com'>foo</a>") }
      let(:node) { doc.children.first }

      it 'removes the link' do
        subject

        expect(node[:href]).to be_nil
      end
    end

    context 'when URI is encoded but still invalid' do
      let(:doc) { HTML::Pipeline.parse("<a href='http://example%EF%BC%9A%E7%BD%91'>foo</a>") }
      let(:node) { doc.children.first }

      it 'removes the link' do
        subject

        expect(node[:href]).to be_nil
      end
    end
  end

  describe "#safe_protocol?" do
    invalid_schemes.each do |scheme|
      context "with the scheme: #{scheme}" do
        let(:doc) { HTML::Pipeline.parse("<a href='#{scheme}alert(1);'>foo</a>") }
        let(:node) { doc.children.first }
        let(:uri) { Addressable::URI.parse(node['href']) }

        it "returns false" do
          expect(object.safe_protocol?(scheme)).to be_falsy
        end
      end
    end
  end

  describe '#sanitize_unsafe_links' do
    let(:env) { { node: 'node' } }

    it 'makes a call to #remove_unsafe_links_method' do
      expect(object).to receive(:remove_unsafe_links).with(env)

      object.sanitize_unsafe_links(env)
    end
  end
end
