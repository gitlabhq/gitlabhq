# frozen_string_literal: true

require 'spec_helper'

describe ErrorTracking::ProjectErrorTrackingSetting do
  set(:project) { create(:project) }

  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'Validations' do
    subject { create(:project_error_tracking_setting, project: project) }

    context 'when api_url is over 255 chars' do
      before do
        subject.api_url = 'https://' + 'a' * 250
      end

      it 'fails validation' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:api_url]).to include('is too long (maximum is 255 characters)')
      end
    end

    context 'With unsafe url' do
      let(:project_error_tracking_setting) { create(:project_error_tracking_setting, project: project) }

      it 'fails validation' do
        project_error_tracking_setting.api_url = "https://replaceme.com/'><script>alert(document.cookie)</script>"

        expect(project_error_tracking_setting).not_to be_valid
      end
    end
  end
end
