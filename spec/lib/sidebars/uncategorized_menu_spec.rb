# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Sidebars::UncategorizedMenu, feature_category: :navigation do
  subject { described_class.new({}) }

  it 'has title and sprite_icon' do
    expect(subject.title).to eq(_("Uncategorized"))
    expect(subject.sprite_icon).to eq("question")
  end
end
