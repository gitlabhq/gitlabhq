# frozen_string_literal: true

require 'spec_helper'

RSpec.describe PagesRemoveWorker do
  it 'does not raise error' do
    expect do
      described_class.new.perform(create(:project).id)
    end.not_to raise_error
  end
end
