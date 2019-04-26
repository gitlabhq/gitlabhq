# frozen_string_literal: true

require 'spec_helper'

describe ProjectMetricsSetting do
  describe 'Associations' do
    it { is_expected.to belong_to(:project) }
  end

  describe 'Validations' do
    context 'when external_dashboard_url is over 255 chars' do
      before do
        subject.external_dashboard_url = 'https://' + 'a' * 250
      end

      it 'fails validation' do
        expect(subject).not_to be_valid
        expect(subject.errors.messages[:external_dashboard_url])
          .to include('is too long (maximum is 255 characters)')
      end
    end

    context 'with unsafe url' do
      before do
        subject.external_dashboard_url = %{https://replaceme.com/'><script>alert(document.cookie)</script>}
      end

      it { is_expected.to be_invalid }
    end

    context 'non ascii chars in external_dashboard_url' do
      before do
        subject.external_dashboard_url = 'http://gitlab.com/api/0/projects/project1/something€'
      end

      it { is_expected.to be_invalid }
    end

    context 'internal url in external_dashboard_url' do
      before do
        subject.external_dashboard_url = 'http://192.168.1.1'
      end

      it { is_expected.to be_valid }
    end

    context 'external_dashboard_url is blank' do
      before do
        subject.external_dashboard_url = ''
      end

      it { is_expected.to be_invalid }
    end
  end
end
