# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::Entities::Package do
  let(:package) { create(:generic_package) }

  subject { described_class.new(package).as_json(namespace: package.project.namespace) }

  it 'exposes correct attributes' do
    expect(subject).to include(
      :id,
      :name,
      :version,
      :package_type,
      :status,
      :_links,
      :created_at,
      :tags,
      :versions
    )
  end

  it 'exposes correct web_path in _links' do
    expect(subject[:_links][:web_path]).to match('/packages/')
  end

  context 'with a terraform_module' do
    let(:package) { create(:terraform_module_package) }

    it 'exposes correct web_path in _links' do
      expect(subject[:_links][:web_path]).to match('/infrastructure_registry/')
    end
  end
end
