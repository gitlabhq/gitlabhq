# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::OtherMarkup do
  let(:context) { {} }

  context 'XSS Checks' do
    links = {
      'links' => {
        file: 'file.rdoc',
        input: 'XSS[JaVaScriPt:alert(1)]',
        output: "\n" + '<p><a>XSS</a></p>' + "\n"
      }
    }
    links.each do |name, data|
      it "does not convert dangerous #{name} into HTML" do
        expect(render(data[:file], data[:input], context)).to eq(data[:output])
      end
    end
  end

  context 'when rendering takes too long' do
    let_it_be(:file_name) { 'foo.bar' }
    let_it_be(:project) { create(:project, :repository) }
    let_it_be(:context) { { project: project } }
    let_it_be(:text) { +'Noël' }

    before do
      stub_const('Gitlab::OtherMarkup::RENDER_TIMEOUT', 0.1)
      allow(GitHub::Markup).to receive(:render) do
        sleep(0.2)
        text
      end
    end

    it 'times out' do
      # expect 3 times because of timeout in SyntaxHighlightFilter and BlockquoteFenceFilter
      expect(Gitlab::RenderTimeout).to receive(:timeout).exactly(3).times.and_call_original
      expect(Gitlab::ErrorTracking).to receive(:track_exception).with(
        instance_of(Timeout::Error),
        project_id: context[:project].id, file_name: file_name,
        class_name: described_class.name.demodulize
      )

      expect(render(file_name, text, context)).to eq("<p>#{text}</p>")
    end
  end

  def render(...)
    described_class.render(...)
  end
end
