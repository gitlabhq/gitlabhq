# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::ImportExport::AfterExportStrategies::WebUploadStrategy do
  include StubRequests

  before do
    allow_next_instance_of(ProjectExportWorker) do |job|
      allow(job).to receive(:jid).and_return(SecureRandom.hex(8))
    end
  end

  let(:example_url) { 'http://www.example.com' }
  let(:strategy) { subject.new(url: example_url, http_method: 'post') }
  let!(:project) { create(:project, :with_export) }
  let!(:user) { build(:user) }

  subject { described_class }

  describe 'validations' do
    it 'only POST and PUT method allowed' do
      %w(POST post PUT put).each do |method|
        expect(subject.new(url: example_url, http_method: method)).to be_valid
      end

      expect(subject.new(url: example_url, http_method: 'whatever')).not_to be_valid
    end

    it 'only allow urls as upload urls' do
      expect(subject.new(url: example_url)).to be_valid
      expect(subject.new(url: 'whatever')).not_to be_valid
    end
  end

  describe '#execute' do
    context 'when upload succeeds' do
      before do
        allow(strategy).to receive(:send_file)
        allow(strategy).to receive(:handle_response_error)
      end

      it 'does not remove the exported project file after the upload' do
        expect(project).not_to receive(:remove_exports)

        strategy.execute(user, project)
      end

      it 'has finished export status' do
        strategy.execute(user, project)

        expect(project.export_status).to eq(:finished)
      end
    end

    context 'when upload fails' do
      it 'stores the export error' do
        stub_full_request(example_url, method: :post).to_return(status: [404, 'Page not found'])

        strategy.execute(user, project)

        errors = project.import_export_shared.errors
        expect(errors).not_to be_empty
        expect(errors.first).to eq "Error uploading the project. Code 404: Page not found"
      end
    end
  end
end
