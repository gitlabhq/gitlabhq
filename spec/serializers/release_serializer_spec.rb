# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ReleaseSerializer do
  let(:user) { create(:user) }
  let(:project) { create :project }

  subject { described_class.new.represent(resource, current_user: user) }

  before do
    project.add_developer(user)
  end

  describe '#represent' do
    context 'when a single object is being serialized' do
      let(:resource) { create(:release, project: project) }

      it 'serializes the label object' do
        expect(subject[:tag]).to eq resource.tag
      end
    end

    context 'when multiple objects are being serialized' do
      let(:resource) { create_list(:release, 3) }

      it 'serializes the array of releases' do
        expect(subject.size).to eq(3)
      end
    end
  end
end
