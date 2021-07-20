# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Redmine do
  describe 'Validations' do
    # if redmine is set in setting the urls are set to defaults
    # therefore the validation passes as the values are not nil
    before do
      settings = {
        'redmine' => {}
      }
      allow(Gitlab.config).to receive(:issues_tracker).and_return(settings)
    end

    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }
      it { is_expected.to validate_presence_of(:new_issue_url) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
      it_behaves_like 'issue tracker integration URL attribute', :issues_url
      it_behaves_like 'issue tracker integration URL attribute', :new_issue_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
      it { is_expected.not_to validate_presence_of(:new_issue_url) }
    end
  end

  describe '.reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does allow # on the reference' do
      expect(described_class.reference_pattern.match('#123')[:issue]).to eq('123')
    end
  end
end
