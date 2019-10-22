# frozen_string_literal: true
require 'spec_helper'

describe Gitlab::GlRepository::RepoType do
  set(:project) { create(:project) }

  describe Gitlab::GlRepository::PROJECT do
    it_behaves_like 'a repo type' do
      let(:expected_identifier) { "project-#{project.id}" }
      let(:expected_id) { project.id.to_s }
      let(:expected_suffix) { "" }
      let(:expected_repository) { project.repository }
    end

    it "knows its type" do
      expect(described_class).not_to be_wiki
      expect(described_class).to be_project
    end
  end

  describe Gitlab::GlRepository::WIKI do
    it_behaves_like 'a repo type' do
      let(:expected_identifier) { "wiki-#{project.id}" }
      let(:expected_id) { project.id.to_s }
      let(:expected_suffix) { ".wiki" }
      let(:expected_repository) { project.wiki.repository }
    end

    it "knows its type" do
      expect(described_class).to be_wiki
      expect(described_class).not_to be_project
    end
  end
end
