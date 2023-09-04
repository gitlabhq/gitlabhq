# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GpgKeys::DestroyService, feature_category: :source_code_management do
  let_it_be(:user) { create(:user) }
  let_it_be(:gpg_key) { create(:gpg_key) }

  subject { described_class.new(user) }

  it 'destroys the GPG key' do
    expect { subject.execute(gpg_key) }.to change(GpgKey, :count).by(-1)
  end

  it 'nullifies the related signatures in batches' do
    stub_const("#{described_class}::BATCH_SIZE", 1)

    first_signature = create(:gpg_signature, gpg_key: gpg_key)
    second_signature = create(:gpg_signature, gpg_key: gpg_key)
    third_signature = create(:gpg_signature, gpg_key: create(:another_gpg_key))

    control = ActiveRecord::QueryRecorder.new { subject.execute(gpg_key) }
    expect(control.count).to eq(5)

    expect(first_signature.reload.gpg_key).to be_nil
    expect(second_signature.reload.gpg_key).to be_nil
    expect(third_signature.reload.gpg_key).not_to be_nil
  end
end
