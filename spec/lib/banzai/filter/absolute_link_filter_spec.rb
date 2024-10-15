# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::AbsoluteLinkFilter, feature_category: :markdown do
  def filter(doc, context = {})
    described_class.call(doc, context)
  end

  context 'with html links' do
    context 'if only_path is false' do
      let(:only_path_context) do
        { only_path: false }
      end

      let(:fake_url) { 'http://www.example.com' }

      before do
        allow(Gitlab.config.gitlab).to receive(:url).and_return(fake_url)
      end

      context 'has the .gfm class' do
        it 'converts a relative url into absolute' do
          doc = filter(link('/foo', 'gfm'), only_path_context)
          expect(doc.at_css('a')['href']).to eq "#{fake_url}/foo"
        end

        it 'does not change the url if it already absolute' do
          doc = filter(link("#{fake_url}/foo", 'gfm'), only_path_context)
          expect(doc.at_css('a')['href']).to eq "#{fake_url}/foo"
        end

        context 'if relative_url_root is set' do
          it 'joins the url without doubling the path' do
            allow(Gitlab.config.gitlab).to receive(:url).and_return("#{fake_url}/gitlab/")
            doc = filter(link("/gitlab/foo", 'gfm'), only_path_context)
            expect(doc.at_css('a')['href']).to eq "#{fake_url}/gitlab/foo"
          end
        end
      end

      context 'has not the .gfm class' do
        it 'does not convert a relative url into absolute' do
          doc = filter(link('/foo'), only_path_context)
          expect(doc.at_css('a')['href']).to eq '/foo'
        end
      end
    end

    context 'if only_path is not false' do
      it 'does not convert a relative url into absolute' do
        expect(filter(link('/foo', 'gfm')).at_css('a')['href']).to eq '/foo'
        expect(filter(link('/foo')).at_css('a')['href']).to eq '/foo'
      end
    end
  end

  it_behaves_like 'pipeline timing check'

  def link(path, css_class = '')
    %(<a class="#{css_class}" href="#{path}">example</a>)
  end
end
