# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Emoji::SkinTones, feature_category: :team_planning do
  let(:bare_modifiers) { %w[tone1 tone2 tone3 tone4 tone5] }

  it 'places every toned emoji in exactly one bucket' do
    toned = TanukiEmoji.index.all
      .select { |character| character.codepoints.codepoints.any? { |cp| described_class::MODIFIERS.cover?(cp) } }
      .map(&:name) - bare_modifiers
    placed = described_class.variants_by_base.values.flatten +
      described_class.mixed_tone_names +
      described_class.unmapped_names

    expect(placed).to match_array(toned)
  end

  it 'freezes the memoized mapping' do
    expect(described_class.variants_by_base).to be_frozen
    expect(described_class.variants_for('wave')).to be_frozen
    expect(described_class.mixed_tone_names).to be_frozen
    expect(described_class.unmapped_names).to be_frozen
  end

  describe '.variants_by_base' do
    subject(:variants_by_base) { described_class.variants_by_base }

    it 'maps every base emoji to exactly five variants' do
      expect(variants_by_base.values).to all(have_attributes(size: 5))
      expect(variants_by_base.values.flatten).to all(be_present)
    end

    it 'orders variants from light to dark for the `_toneN` naming scheme' do
      expect(variants_by_base['thumbsup']).to eq(%w[thumbsup_tone1 thumbsup_tone2 thumbsup_tone3 thumbsup_tone4
        thumbsup_tone5])
    end

    it 'orders variants from light to dark for the `_skin_tone` naming scheme' do
      expect(variants_by_base['people_holding_hands']).to eq(
        %w[
          people_holding_hands_light_skin_tone
          people_holding_hands_medium_light_skin_tone
          people_holding_hands_medium_skin_tone
          people_holding_hands_medium_dark_skin_tone
          people_holding_hands_dark_skin_tone
        ]
      )
    end

    it 'matches a base that carries a variation selector to variants that do not' do
      expect(variants_by_base['spy']).to have_attributes(size: 5)
    end

    it 'resolves duplicate names the way find_by_alpha_code does' do
      expect(TanukiEmoji.find_by_alpha_code('man_in_tuxedo').codepoints).to eq('🤵')
      expect(variants_by_base['man_in_tuxedo']).to eq(%w[man_in_tuxedo_tone1 man_in_tuxedo_tone2 man_in_tuxedo_tone3
        man_in_tuxedo_tone4 man_in_tuxedo_tone5])
    end

    it 'ignores the bare tone modifiers' do
      expect(variants_by_base.keys).not_to include(*bare_modifiers)
      expect(variants_by_base.values.flatten).not_to include(*bare_modifiers)
    end
  end

  describe '.mixed_tone_names' do
    subject(:mixed_tone_names) { described_class.mixed_tone_names }

    it 'lists the two-person emoji whose people have different tones' do
      expect(mixed_tone_names).to include('handshake_light_skin_tone_medium_skin_tone')
      expect(mixed_tone_names).not_to include('handshake_tone2', 'handshake')
    end

    it 'does not overlap with the variants' do
      expect(mixed_tone_names & described_class.variants_by_base.values.flatten).to be_empty
    end
  end

  describe '.unmapped_names' do
    subject(:unmapped_names) { described_class.unmapped_names }

    it 'lists the single-tone variants of the man in a tuxedo, whose base name resolves to the person' do
      expect(unmapped_names).to contain_exactly(
        'man_in_tuxedo_light_skin_tone',
        'man_in_tuxedo_medium_light_skin_tone',
        'man_in_tuxedo_medium_skin_tone',
        'man_in_tuxedo_medium_dark_skin_tone',
        'man_in_tuxedo_dark_skin_tone'
      )
    end

    it 'does not overlap with the variants or the mixed names' do
      expect(unmapped_names & described_class.variants_by_base.values.flatten).to be_empty
      expect(unmapped_names & described_class.mixed_tone_names).to be_empty
    end
  end

  describe '.base_name' do
    it 'returns the base for a variant and the name itself otherwise' do
      expect(described_class.base_name('thumbsup_tone3')).to eq('thumbsup')
      expect(described_class.base_name('thumbsup')).to eq('thumbsup')
      expect(described_class.base_name('rocket')).to eq('rocket')
      mixed = 'handshake_light_skin_tone_medium_skin_tone'
      expect(described_class.base_name(mixed)).to eq(mixed)
      expect(described_class.base_name('man_in_tuxedo_medium_skin_tone')).to eq('man_in_tuxedo_medium_skin_tone')
    end
  end

  describe '.variants_for' do
    it 'returns the five variants for a base or any of its variants' do
      expect(described_class.variants_for('wave')).to eq(described_class.variants_for('wave_tone5'))
      expect(described_class.variants_for('wave')).to have_attributes(size: 5)
      expect(described_class.variants_for('rocket')).to eq([])
      expect(described_class.variants_for('man_in_tuxedo_medium_skin_tone')).to eq([])
    end
  end

  describe 'fixtures/emojis/skin_tones.json' do
    it 'is up to date' do
      fixture = File.read(Rails.root.join('fixtures/emojis/skin_tones.json'))
      generated = "#{Gitlab::Json.pretty_generate(described_class.to_h)}\n"

      expect(fixture).to eq(generated), 'Stale fixture, run `bundle exec rake tanuki_emoji:skin_tones`'
    end
  end
end
