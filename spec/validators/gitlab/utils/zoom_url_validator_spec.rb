# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Utils::ZoomUrlValidator do
  let(:zoom_meeting) { build(:zoom_meeting) }

  describe 'validations' do
    context 'when zoom link starts with https' do
      it 'passes validation' do
        zoom_meeting.url = 'https://zoom.us/j/123456789'

        expect(zoom_meeting.valid?).to eq(true)
        expect(zoom_meeting.errors).to be_empty
      end
    end

    shared_examples 'zoom link does not start with https' do |url|
      it 'fails validation' do
        zoom_meeting.url = url
        expect(zoom_meeting.valid?).to eq(false)

        expect(zoom_meeting.errors).to be_present
        expect(zoom_meeting.errors.added?(:url, 'must contain one valid Zoom URL')).to be true
      end
    end

    context 'when zoom link does not start with https' do
      include_examples 'zoom link does not start with https', 'http://zoom.us/j/123456789'

      context 'when zoom link does not start with a scheme' do
        include_examples 'zoom link does not start with https', 'testinghttp://zoom.us/j/123456789'
      end
    end
  end
end
