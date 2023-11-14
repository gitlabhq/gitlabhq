# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProjectSnippet, feature_category: :source_code_management do
  describe "Associations" do
    it { is_expected.to belong_to(:project) }
  end

  describe 'scopes' do
    describe '.by_project' do
      subject { described_class.by_project(project) }

      let_it_be(:project) { create(:project) }
      let_it_be(:snippet1) { create(:project_snippet, project: project) }
      let_it_be(:snippet2) { create(:project_snippet, project: build(:project)) }
      let_it_be(:snippet3) { create(:personal_snippet) }

      it { is_expected.to contain_exactly(snippet1) }
    end
  end

  describe "Validation" do
    it { is_expected.to validate_presence_of(:project) }
    it { is_expected.to validate_inclusion_of(:secret).in_array([false]) }
  end

  describe '#embeddable?' do
    [
      { project: :public,   snippet: :public,   embeddable: true },
      { project: :internal, snippet: :public,   embeddable: false },
      { project: :private,  snippet: :public,   embeddable: false },
      { project: :public,   snippet: :internal, embeddable: false },
      { project: :internal, snippet: :internal, embeddable: false },
      { project: :private,  snippet: :internal, embeddable: false },
      { project: :public,   snippet: :private,  embeddable: false },
      { project: :internal, snippet: :private,  embeddable: false },
      { project: :private,  snippet: :private,  embeddable: false }
    ].each do |combination|
      it 'only returns true when both project and snippet are public' do
        project = create(:project, combination[:project])
        snippet = build(:project_snippet, combination[:snippet], project: project)

        expect(snippet.embeddable?).to eq(combination[:embeddable])
      end
    end
  end

  it_behaves_like 'model with repository' do
    let_it_be(:container) { create(:project_snippet, :repository) }
    let(:stubbed_container) { build_stubbed(:project_snippet) }
    let(:expected_full_path) { "#{container.project.full_path}/snippets/#{container.id}" }
    let(:expected_web_url_path) { "#{container.project.full_path}/-/snippets/#{container.id}" }
  end
end
