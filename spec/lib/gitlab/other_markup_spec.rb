require 'spec_helper'

describe Gitlab::OtherMarkup do
  let(:context) { {} }

  context "XSS Checks" do
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

  def render(*args)
    described_class.render(*args)
  end
end
