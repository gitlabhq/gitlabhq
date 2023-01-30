# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::TableOfContentsTagFilter, feature_category: :team_planning do
  include FilterSpecHelper

  context 'table of contents' do
    shared_examples 'table of contents tag' do
      it 'replaces toc tag with ToC result' do
        doc = filter(html, {}, { toc: "FOO" })

        expect(doc.to_html).to eq("FOO")
      end

      it 'handles an empty ToC result' do
        doc = filter(html)

        expect(doc.to_html).to eq ''
      end
    end

    context '[[_TOC_]] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[[<em>TOC</em>]]</p>' }
      end
    end

    context '[[_toc_]] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[[<em>toc</em>]]</p>' }
      end
    end

    context '[TOC] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[TOC]</p>' }
      end
    end

    context '[toc] as tag' do
      it_behaves_like 'table of contents tag' do
        let(:html) { '<p>[toc]</p>' }
      end
    end
  end
end
