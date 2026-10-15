# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'tanuki_emoji rake tasks', :silence_stdout, feature_category: :team_planning do
  before do
    Rake.application.rake_require 'tasks/tanuki_emoji'
  end

  describe 'tanuki_emoji:skin_tones' do
    let(:skin_tones_path) { Rails.root.join('fixtures/emojis/skin_tones.json').to_s }
    let(:handle) { StringIO.new }

    it 'writes the skin tone mapping fixture' do
      allow(File).to receive(:open).and_call_original
      allow(File).to receive(:open).with(skin_tones_path, 'w').and_yield(handle)

      run_rake_task('tanuki_emoji:skin_tones')

      expect(handle.string).to eq("#{Gitlab::Json.pretty_generate(Gitlab::Emoji::SkinTones.to_h)}\n")
    end
  end
end
