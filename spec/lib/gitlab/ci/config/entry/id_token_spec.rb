# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Ci::Config::Entry::IdToken do
  context 'when given `aud` as a string' do
    it 'is valid' do
      config = { aud: 'https://gitlab.com' }
      id_token = described_class.new(config)

      id_token.compose!

      expect(id_token).to be_valid
      expect(id_token.value).to eq(aud: 'https://gitlab.com')
    end
  end

  context 'when given `aud` is a variable' do
    it 'is valid' do
      config = { aud: '$WATHEVER' }
      id_token = described_class.new(config)

      id_token.compose!

      expect(id_token).to be_valid
    end
  end

  context 'when given `aud` includes a variable' do
    it 'is valid' do
      config = { aud: 'blah-$WATHEVER' }
      id_token = described_class.new(config)

      id_token.compose!

      expect(id_token).to be_valid
    end
  end

  context 'when given `aud` as an array' do
    it 'is valid and concatenates the values' do
      config = { aud: ['https://gitlab.com', 'https://aws.com'] }
      id_token = described_class.new(config)

      id_token.compose!

      expect(id_token).to be_valid
      expect(id_token.value).to eq(aud: ['https://gitlab.com', 'https://aws.com'])
    end
  end

  context 'when given `aud` as an array with variables' do
    it 'is valid and concatenates the values' do
      config = { aud: ['$WATHEVER', 'blah-$WATHEVER'] }
      id_token = described_class.new(config)

      id_token.compose!

      expect(id_token).to be_valid
    end
  end

  context 'when not given an `aud`' do
    it 'is invalid' do
      config = {}
      id_token = described_class.new(config)

      id_token.compose!

      expect(id_token).not_to be_valid
      expect(id_token.errors).to match_array([
        'id token config missing required keys: aud',
                                               'id token aud should be an array of strings or a string'
      ])
    end
  end

  context 'when given an unknown keyword' do
    it 'is invalid' do
      config = { aud: 'https://gitlab.com', unknown: 'test' }
      id_token = described_class.new(config)

      id_token.compose!

      expect(id_token).not_to be_valid
      expect(id_token.errors).to match_array([
        'id token config contains unknown keys: unknown'
      ])
    end
  end
end
