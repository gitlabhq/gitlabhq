# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Keys::DestroyService, feature_category: :source_code_management do
  let(:user) { create(:user) }

  subject { described_class.new(user) }

  it 'destroys a key' do
    key = create(:personal_key)

    expect { subject.execute(key) }.to change(Key, :count).by(-1)
  end
end
