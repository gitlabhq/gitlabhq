# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::PlanLimit do
  let(:plan_limits) { create(:plan_limits) }

  subject { described_class.new(plan_limits).as_json }

  it 'exposes correct attributes' do
    expect(subject).to include(
      :conan_max_file_size,
      :generic_packages_max_file_size,
      :maven_max_file_size,
      :npm_max_file_size,
      :nuget_max_file_size,
      :pypi_max_file_size,
      :terraform_module_max_file_size
    )
  end

  it 'does not expose id and plan_id' do
    expect(subject).not_to include(:id, :plan_id)
  end
end
