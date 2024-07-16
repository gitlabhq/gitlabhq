# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Uploads::DestroyService, feature_category: :shared do
  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user) }
  let_it_be_with_reload(:upload) { create(:upload, :issuable_upload, model: project) }

  let(:model) { project }
  let(:service) { described_class.new(model, user) }

  describe '#execute' do
    subject { service.execute(upload) }

    shared_examples_for 'upload not found' do
      it 'does not delete any upload' do
        expect { subject }.not_to change { Upload.count }
      end

      it 'returns an error' do
        expect(subject[:status]).to eq(:error)
        expect(subject[:message]).to eq("The resource that you are attempting to access does not "\
                                        "exist or you don't have permission to perform this action.")
      end
    end

    context 'when user is nil' do
      let(:user) { nil }

      it_behaves_like 'upload not found'
    end

    context 'when user cannot destroy upload' do
      before do
        project.add_developer(user)
      end

      it_behaves_like 'upload not found'
    end

    context 'when user can destroy upload' do
      before do
        project.add_maintainer(user)
      end

      it 'deletes the upload' do
        expect { subject }.to change { Upload.count }.by(-1)
      end

      it 'returns success response' do
        expect(subject[:status]).to eq(:success)
        expect(subject[:upload]).to eq(upload)
      end

      context 'when upload belongs to other model' do
        let_it_be(:upload) { create(:upload, :namespace_upload) }

        it_behaves_like 'upload not found'
      end

      context 'when upload destroy fails' do
        before do
          allow(upload).to receive(:destroy).and_return(false)
        end

        it 'returns error' do
          expect(subject[:status]).to eq(:error)
          expect(subject[:message]).to eq('Upload could not be deleted.')
        end
      end
    end
  end
end
