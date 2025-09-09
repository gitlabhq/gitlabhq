# frozen_string_literal: true

require "spec_helper"

RSpec.describe WikiPage, feature_category: :wiki do
  it_behaves_like 'wiki_page', :project

  describe 'wiki page references' do
    describe '#reference_pattern' do
      let(:match_data) { described_class.reference_pattern.match(link_reference_url) }

      context 'with full namespace with project' do
        let(:link_reference_url) { '[wiki_page:namespace/project:foobar/qux]' }

        it 'matches with expected attributes' do
          expect(match_data['group_or_project_namespace']).to eq('namespace/project')
          expect(match_data['wiki_page']).to eq('foobar/qux')
        end
      end

      context 'without a namespace' do
        let(:link_reference_url) { '[wiki_page:foobar/qux]' }

        it 'matches with expected attributes' do
          expect(match_data['group_or_project_namespace']).to be_nil
          expect(match_data['wiki_page']).to eq('foobar/qux')
        end
      end
    end

    describe '#link_reference_pattern' do
      let(:match_data) { described_class.link_reference_pattern.match(link_reference_url) }

      context 'with project wiki page url' do
        let(:link_reference_url) { 'http://localhost/namespace/project/-/wikis/foobar/qux' }

        it 'matches with expected attributes' do
          expect(match_data['group_or_project_namespace']).to eq('namespace/project')
          expect(match_data['wiki_page']).to eq('foobar/qux')
        end
      end

      context 'with group wiki page url' do
        let(:link_reference_url) { 'http://localhost/groups/namespace/subgroup/-/wikis/foobar/qux' }

        it 'matches with expected attributes' do
          expect(match_data['group_or_project_namespace']).to eq('namespace/subgroup')
          expect(match_data['wiki_page']).to eq('foobar/qux')
        end
      end
    end
  end
end
