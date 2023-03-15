# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ProtectedTags::CreateService, feature_category: :compliance_management do
  let(:project) { create(:project) }
  let(:user) { project.first_owner }
  let(:params) do
    {
      name: name,
      create_access_levels_attributes: [{ access_level: Gitlab::Access::MAINTAINER }]
    }
  end

  describe '#execute' do
    let(:name) { 'tag' }

    subject(:service) { described_class.new(project, user, params) }

    it 'creates a new protected tag' do
      expect { service.execute }.to change(ProtectedTag, :count).by(1)
      expect(project.protected_tags.last.create_access_levels.map(&:access_level)).to eq([Gitlab::Access::MAINTAINER])
    end

    context 'protecting a tag with a name that contains HTML tags' do
      let(:name) { 'foo<b>bar<\b>' }

      subject(:service) { described_class.new(project, user, params) }

      it 'creates a new protected tag' do
        expect { service.execute }.to change(ProtectedTag, :count).by(1)
        expect(project.protected_tags.last.name).to eq(name)
      end
    end
  end
end
