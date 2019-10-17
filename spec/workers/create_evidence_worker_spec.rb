# frozen_string_literal: true

require 'spec_helper'

describe CreateEvidenceWorker do
  let!(:release) { create(:release) }

  it 'creates a new Evidence' do
    expect { described_class.new.perform(release.id) }.to change(Evidence, :count).by(1)
  end
end
