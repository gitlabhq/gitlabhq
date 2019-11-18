# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::GithubImport::Importer::IssueAndLabelLinksImporter do
  describe '#execute' do
    it 'imports an issue and its labels' do
      issue = double(:issue)
      project = double(:project)
      client = double(:client)
      label_links_instance = double(:label_links_importer)
      importer = described_class.new(issue, project, client)

      expect(Gitlab::GithubImport::Importer::IssueImporter)
        .to receive(:import_if_issue)
        .with(issue, project, client)

      expect(Gitlab::GithubImport::Importer::LabelLinksImporter)
        .to receive(:new)
        .with(issue, project, client)
        .and_return(label_links_instance)

      expect(label_links_instance)
        .to receive(:execute)

      importer.execute
    end
  end
end
