# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeys::DestroyService do
  let(:user) { create(:user) }

  subject { described_class.new(user) }

  it 'destroys the GPG key' do
    gpg_key = create(:gpg_key)

    expect { subject.execute(gpg_key) }.to change(GpgKey, :count).by(-1)
  end
end
