# frozen_string_literal: true

require 'spec_helper'

describe MicrosoftTeams::Activity do
  subject { described_class.new(title: 'title', subtitle: 'subtitle', text: 'text', image: 'image') }

  describe '#prepare' do
    it 'returns the correct JSON object' do
      expect(subject.prepare).to eq({
        'activityTitle' => 'title',
        'activitySubtitle' => 'subtitle',
        'activityText' => 'text',
        'activityImage' => 'image'
      })
    end
  end
end
