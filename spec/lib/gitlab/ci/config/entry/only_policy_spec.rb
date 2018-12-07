# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::OnlyPolicy do
  let(:entry) { described_class.new(config) }

  it_behaves_like 'correct only except policy'

  describe '.default' do
    it 'haa a default value' do
      expect(described_class.default).to eq( { refs: %w[branches tags] } )
    end
  end
end
