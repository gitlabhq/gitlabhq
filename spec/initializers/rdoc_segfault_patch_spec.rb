# frozen_string_literal: true

RSpec.describe 'RDoc segfault patch fix' do
  describe 'RDoc::Markup::ToHtml' do
    describe '#parseable?' do
      it 'returns false' do
        to_html = RDoc::Markup::ToHtml.new( nil)

        expect(to_html.parseable?('"def foo; end"')).to eq(false)
      end
    end
  end

  describe 'RDoc::Markup::Verbatim' do
    describe 'ruby?' do
      it 'returns false' do
        verbatim = RDoc::Markup::Verbatim.new('def foo; end')
        verbatim.format = :ruby

        expect(verbatim.ruby?).to eq(false)
      end
    end
  end
end
