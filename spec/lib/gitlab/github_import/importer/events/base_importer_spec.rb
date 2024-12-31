# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::GithubImport::Importer::Events::BaseImporter, feature_category: :importers do
  let(:project) { instance_double('Project') }
  let(:client) { instance_double('Gitlab::GithubImport::Client') }
  let(:issue_event) { instance_double('Gitlab::GithubImport::Representation::IssueEvent') }
  let(:importer_class) { Class.new(described_class) }
  let(:importer_instance) { importer_class.new(project, client) }

  describe '#execute' do
    it { expect { importer_instance.execute(issue_event) }.to raise_error(NotImplementedError) }
  end
end
