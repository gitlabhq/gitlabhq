# frozen_string_literal: true

require 'spec_helper'

RSpec.describe OpenProjectService do
  describe 'Validations' do
    context 'when service is active' do
      before do
        subject.active = true
      end

      it { is_expected.to validate_presence_of(:url) }
      it { is_expected.to validate_presence_of(:token) }
      it { is_expected.to validate_presence_of(:project_identifier_code) }

      it_behaves_like 'issue tracker service URL attribute', :url
      it_behaves_like 'issue tracker service URL attribute', :api_url
    end

    context 'when service is inactive' do
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
