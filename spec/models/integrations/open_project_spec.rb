# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Integrations::OpenProject do
  describe 'Validations' do
    context 'when integration is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:project_identifier_code) }

      it_behaves_like 'issue tracker integration URL attribute', :url
      it_behaves_like 'issue tracker integration URL attribute', :api_url
    end

    context 'when integration is inactive' do
      before do
        subject.active = false
      end

      it { is_expected.not_to validate_presence_of(:url) }
      it { is_expected.not_to validate_presence_of(:token) }
      it { is_expected.not_to validate_presence_of(:project_identifier_code) }
    end
  end

  describe 'Associations' do
    it { is_expected.to belong_to :project }
    it { is_expected.to have_one :service_hook }
  end
end
