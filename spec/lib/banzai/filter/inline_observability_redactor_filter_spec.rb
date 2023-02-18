# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::InlineObservabilityRedactorFilter, feature_category: :metrics do
  include FilterSpecHelper

  let_it_be(:group) { create(:group) }

  let(:url) { "#{Gitlab::Observability.observability_url}/#{group.id}/explore" }
  let(:input) { %(<a href="#{url}">example</a>) }
  let(:doc) { filter(input) }

  context 'without an observability placeholder' do
    it 'leaves regular links unchanged' do
      expect(doc.to_s).to eq input
    end
  end

  shared_examples 'redacts the placeholder' do
    it 'redacts the placeholder' do
      expect(doc.to_s).to be_empty
    end
  end

  context 'with an observability placeholder' do
    let(:input) { %(<div class="js-render-observability" data-frame-url="#{url}"></div>) }

    context 'when no user is logged in' do
      it_behaves_like 'redacts the placeholder'
    end

    context 'with invalid observability url' do
      let(:url) { "#{Gitlab::Observability.observability_url}/foo/explore" }

      it_behaves_like 'redacts the placeholder'
    end

    context 'with missing observability frame url' do
      let(:input) { %(<div class="js-render-observability"></div>) }

      it_behaves_like 'redacts the placeholder'
    end

    context 'when the user does not have permission to access the group' do
      let(:user) { create(:user) }
      let(:doc) { filter(input, current_user: user) }

      it_behaves_like 'redacts the placeholder'
    end

    context 'when the user is not a developer of the group' do
      let(:user) { create(:user) }
      let(:doc) { filter(input, current_user: user) }

      before do
        group.add_reporter(user)
      end

      it_behaves_like 'redacts the placeholder'
    end

    context 'when the user is a developer of the group' do
      let(:user) { create(:user) }
      let(:doc) { filter(input, current_user: user) }

      before do
        group.add_developer(user)
      end

      it 'leaves the placeholder' do
        expect(CGI.unescapeHTML(doc.to_s)).to eq(input)
      end

      context 'with over 100 embeds' do
        let(:embed) { %(<div class="js-render-observability" data-frame-url="#{url}"></div>) }
        let(:input) { embed * 150 }

        it 'redacts ill-advised embeds' do
          expect(doc.to_s.length).to eq(embed.length * 100)
        end
      end
    end
  end
end
