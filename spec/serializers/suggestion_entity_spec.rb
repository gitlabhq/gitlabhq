# frozen_string_literal: true

require 'spec_helper'

describe SuggestionEntity do
  include RepoHelpers

  let(:user) { create(:user) }
  let(:request) { double('request', current_user: user) }
  let(:suggestion) { create(:suggestion) }
  let(:entity) { described_class.new(suggestion, request: request) }

  subject { entity.as_json }

  it 'exposes correct attributes' do
    expect(subject.keys).to match_array([:id, :appliable, :applied, :diff_lines, :current_user])
  end

  it 'exposes current user abilities' do
    expect(subject[:current_user]).to include(:can_apply)
  end
end
