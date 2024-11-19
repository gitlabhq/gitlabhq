# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AlertManagement::MetricImages::UploadService, feature_category: :observability do
  subject(:service) { described_class.new(alert, current_user, params) }

  let_it_be_with_refind(:project) { create(:project) }
  let_it_be_with_refind(:alert) { create(:alert_management_alert, project: project) }
  let_it_be_with_refind(:current_user) { create(:user) }

  let(:params) do
    {
      file: fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg'),
      url: 'https://www.gitlab.com'
    }
  end

  describe '#execute' do
    subject { service.execute }

    shared_examples 'uploads the metric' do
      it 'uploads the metric and returns a success' do
        expect { subject }.to change(AlertManagement::MetricImage, :count).by(1)
        expect(subject.success?).to eq(true)
        expect(subject.payload).to match({ metric: instance_of(AlertManagement::MetricImage), alert: alert })
      end
    end

    shared_examples 'no metric saved, an error given' do |message|
      it 'returns an error and does not upload', :aggregate_failures do
        expect(subject.success?).to eq(false)
        expect(subject.message).to match(a_string_matching(message))
        expect(AlertManagement::MetricImage.count).to eq(0)
      end
    end

    context 'user does not have permissions' do
      it_behaves_like 'no metric saved, an error given', 'You are not authorized to upload metric images'
    end

    context 'user has permissions' do
      before_all do
        project.add_developer(current_user)
      end

      it_behaves_like 'uploads the metric'

      context 'no url given' do
        let(:params) do
          {
            file: fixture_file_upload('spec/fixtures/rails_sample.jpg', 'image/jpg')
          }
        end

        it_behaves_like 'uploads the metric'
      end

      context 'record invalid' do
        let(:params) do
          {
            file: fixture_file_upload('spec/fixtures/doc_sample.txt', 'text/plain'),
            url: 'https://www.gitlab.com'
          }
        end

        it_behaves_like 'no metric saved, an error given',
          /File does not have a supported extension. Only png, jpg, jpeg, gif, bmp, tiff, ico, and webp are supported/
      end

      context 'user is guest' do
        before_all do
          project.add_guest(current_user)
        end

        it_behaves_like 'no metric saved, an error given', 'You are not authorized to upload metric images'
      end
    end
  end
end
