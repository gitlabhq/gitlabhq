require 'spec_helper'

describe Gitlab::OtherMarkup, lib: true do
  context "XSS Checks" do
    it "does not convert dangerous #{name} into HTML" do
      context = {}
      filename = 'file.rdoc'
      input = 'XSS[JaVaScriPt:alert(1)]'
      output = '<p><a>XSS</a></p>'

      expect(render(filename, input, context)).to eql output
    end
  end

  context 'external links' do
    it 'adds the `rel` attribute to the link' do
      context = {}
      output = render('file.rdoc', '{Google}[https://google.com]', context)

      expect(output).to include('rel="nofollow noreferrer noopener"')
    end
  end

  def render(*args)
    described_class.render(*args).strip
  end
end
