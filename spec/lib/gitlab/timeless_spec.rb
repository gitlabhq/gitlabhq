# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Timeless, feature_category: :shared do
  let(:model) { build(:user) }

  it 'disables record_timestamps temporarily' do
    expect(model.record_timestamps).to eq(true)

    Gitlab::Timeless.timeless(model) do |m|
      expect(m.record_timestamps).to eq(false)
      expect(model.record_timestamps).to eq(false)
    end

    expect(model.record_timestamps).to eq(true)
  end

  it 'does not record created_at' do
    Gitlab::Timeless.timeless(model) do
      model.save!(username: "#{model.username}-a")
    end

    expect(model.created_at).to be(nil)
  end

  it 'does not record updated_at' do
    model.save!
    previous = model.updated_at

    Gitlab::Timeless.timeless(model) do
      model.update!(username: "#{model.username}-a")
    end

    expect(model.updated_at).to eq(previous)
  end
end
