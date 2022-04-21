# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Projects::Topic do
  let(:topic) { create(:topic) }

  subject { described_class.new(topic).as_json }

  it 'exposes correct attributes' do
    expect(subject).to include(
      :id,
      :name,
      :title,
      :description,
      :total_projects_count,
      :avatar_url
    )
  end
end
