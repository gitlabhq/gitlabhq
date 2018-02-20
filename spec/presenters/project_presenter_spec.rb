require 'spec_helper'

describe ProjectPresenter do
  let(:user) { create(:user) }
  let(:project) { create(:project) }
  let(:presenter) { described_class.new(project, current_user: user) }

  describe '#license_short_name' do
    context 'when project.repository has a license_key' do
      it 'returns the nickname of the license if present' do
        allow(project.repository).to receive(:license_key).and_return('agpl-3.0')

        expect(presenter.license_short_name).to eq('GNU AGPLv3')
      end

      it 'returns the name of the license if nickname is not present' do
        allow(project.repository).to receive(:license_key).and_return('mit')

        expect(presenter.license_short_name).to eq('MIT License')
      end
    end

    context 'when project.repository has no license_key but a license_blob' do
      it 'returns LICENSE' do
        allow(project.repository).to receive(:license_key).and_return(nil)

        expect(presenter.license_short_name).to eq('LICENSE')
      end
    end
  end
end
