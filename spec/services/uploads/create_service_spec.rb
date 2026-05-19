# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploads::CreateService, feature_category: :team_planning do
  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:user) { create(:user, developer_of: [project, group]) }

  let(:file) { fixture_file_upload('spec/fixtures/dk.png', 'image/png') }

  describe '#execute' do
    subject(:result) { described_class.new(parent, user, file: file).execute }

    shared_examples 'successful upload' do
      it 'returns success' do
        expect(result).to be_success
      end

      it 'creates an upload' do
        expect { result }.to change { Upload.count }.by(1)
      end

      it 'returns upload data in payload' do
        expect(result.payload[:upload]).to be_a(Upload)
        expect(result.payload[:markdown]).to match(%r{!\[dk\]\(/uploads/\h{32}/dk\.png\)})
        expect(result.payload[:url]).to match(%r{/uploads/\h{32}/dk\.png})
        expect(result.payload[:alt]).to eq('dk')
        expect(result.payload[:full_path]).to be_present
      end
    end

    context 'when uploading to a project' do
      let(:parent) { project }

      it_behaves_like 'successful upload'

      it 'returns full_path for project' do
        expect(result.payload[:full_path]).to match(%r{/-/project/#{project.id}/uploads/\h{32}/dk\.png})
      end
    end

    context 'when uploading to a group' do
      let(:parent) { group }

      it_behaves_like 'successful upload'

      it 'returns full_path for group' do
        expect(result.payload[:full_path]).to match(%r{/-/group/#{group.id}/uploads/\h{32}/dk\.png})
      end
    end

    context 'when upload fails' do
      let(:parent) { project }

      before do
        allow_next_instance_of(UploadService) do |service|
          allow(service).to receive(:execute).and_return(nil)
        end
      end

      it 'returns error' do
        expect(result).to be_error
        expect(result.message).to eq('Failed to upload file.')
      end

      it 'returns empty payload' do
        expect(result.payload[:upload]).to be_nil
        expect(result.payload[:markdown]).to be_nil
        expect(result.payload[:url]).to be_nil
        expect(result.payload[:alt]).to be_nil
        expect(result.payload[:full_path]).to be_nil
      end
    end
  end
end
