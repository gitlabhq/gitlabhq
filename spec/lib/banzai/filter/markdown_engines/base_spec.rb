# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Banzai::Filter::MarkdownEngines::Base, feature_category: :team_planning do
  it 'raise error if render not implemented' do
    engine = described_class.new({})

    expect { engine.render('# hi') }.to raise_error(NotImplementedError)
  end

  it 'turns off sourcepos' do
    engine = described_class.new({ no_sourcepos: true })

    expect(engine.send(:sourcepos_disabled?)).to be_truthy
  end
end
