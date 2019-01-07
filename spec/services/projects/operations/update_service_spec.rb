# frozen_string_literal: true

require 'spec_helper'

describe Projects::Operations::UpdateService do
  set(:user) { create(:user) }
  set(:project) { create(:project) }

  let(:result) { subject.execute }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with inappropriate params' do
      let(:params) { { name: '' } }

      let!(:original_name) { project.name }

      it 'ignores params' do
        expect(result[:status]).to eq(:success)
        expect(project.reload.name).to eq(original_name)
      end
    end
  end
end
