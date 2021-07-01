# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::Youtrack do
  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end

  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:project_url) }
      it { is_expected.to validate_presence_of(:issues_url) }

      it_behaves_like 'issue tracker integration URL attribute', :project_url
      it_behaves_like 'issue tracker integration URL attribute', :issues_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:project_url) }
      it { is_expected.not_to validate_presence_of(:issues_url) }
    end
  end

  describe '.reference_pattern' do
    it_behaves_like 'allows project key on reference pattern'

    it 'does allow project prefix on the reference' do
      expect(described_class.reference_pattern.match('YT-123')[:issue]).to eq('YT-123')
    end

    it 'allows lowercase project key on the reference' do
      expect(described_class.reference_pattern.match('yt-123')[:issue]).to eq('yt-123')
    end
  end
end
