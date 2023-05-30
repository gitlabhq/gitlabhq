# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Projects::WikisController, feature_category: :wiki do
  using RSpec::Parameterized::TableSyntax

  let_it_be(:user) { create(:user) }
  let_it_be(:diagramsnet_is_enabled) { false }
  let_it_be(:diagramsnet_url) { 'https://url.diagrams.net' }
  let_it_be(:project) { create(:project, :wiki_repo, namespace: user.namespace) }
  let_it_be(:project_wiki) { create(:project_wiki, project: project, user: user) }
  let_it_be(:wiki_page) do
    create(:wiki_page,
      wiki: project_wiki,
      title: 'home', content: "Look at this [image](#{path})\n\n ![alt text](#{path})")
  end

  let_it_be(:csp_nonce) { 'just=some=noncense' }

  before do
    sign_in(user)
    allow(Gitlab::CurrentSettings)
      .to receive(:diagramsnet_enabled?)
      .and_return(diagramsnet_is_enabled)
    allow(Gitlab::CurrentSettings)
      .to receive(:diagramsnet_url)
      .and_return(diagramsnet_url)

    allow_next_instance_of(described_class) do |instance|
      allow(instance).to receive(:content_security_policy_nonce).and_return(csp_nonce)
    end
  end

  shared_examples 'embed.diagrams.net frame-src directive' do
    context 'when diagrams.net disabled' do
      it 'drawio frame-src directive to the Content Security Policy header' do
        frame_src = response.headers['Content-Security-Policy'].split(';')
          .map(&:strip)
          .find { |entry| entry.starts_with?('frame-src') }

        expect(frame_src).not_to include(diagramsnet_url)
      end
    end

    context 'when diagrams.net enabled' do
      let(:diagramsnet_is_enabled) { true }

      it 'drawio frame-src directive to the Content Security Policy header' do
        frame_src = response.headers['Content-Security-Policy'].split(';')
          .map(&:strip)
          .find { |entry| entry.starts_with?('frame-src') }

        expect(frame_src).to include(diagramsnet_url)
      end
    end
  end

  describe 'CSP policy' do
    describe '#new' do
      before do
        get wiki_path(project_wiki, action: :new)
      end

      it_behaves_like 'embed.diagrams.net frame-src directive'
    end

    describe '#edit' do
      before do
        get wiki_page_path(project_wiki, wiki_page, action: 'edit')
      end

      it_behaves_like 'embed.diagrams.net frame-src directive'
    end

    describe '#create' do
      before do
        # Creating a page with an invalid title to render edit page
        post wiki_path(project_wiki, action: 'create'), params: { wiki: { title: 'home' } }
      end

      it_behaves_like 'embed.diagrams.net frame-src directive'
    end

    describe '#update' do
      before do
        # Setting an invalid page title to render edit page
        put wiki_page_path(project_wiki, wiki_page), params: { wiki: { title: '' } }
      end

      it_behaves_like 'embed.diagrams.net frame-src directive'
    end
  end
end
