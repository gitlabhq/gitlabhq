require 'spec_helper'

describe Gitlab::OtherMarkup, lib: true do
  context "XSS Checks" do
    links = {
      'links' => {
        file: 'file.rdoc',
        input: 'XSS[JaVaScriPt:alert(1)]',
        output: '<p><a>XSS</a></p>'
      }
    }
    links.each do |name, data|
      it "does not convert dangerous #{name} into HTML" do
        expect(render(data[:file], data[:input], context)).to eql data[:output]
      end
    end
  end

  def render(*args)
    described_class.render(*args)
  end
end
