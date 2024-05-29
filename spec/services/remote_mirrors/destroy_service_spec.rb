# frozen_string_literal: true

require 'spec_helper'

RSpec.describe RemoteMirrors::DestroyService, feature_category: :source_code_management do
  subject(:service) { described_class.new(project, user) }

  let_it_be(:project) { create(:project) }
  let_it_be(:user) { create(:user, maintainer_of: project) }

  let!(:remote_mirror) { create(:remote_mirror, project: project) }

  describe '#execute', :aggregate_failures do
    subject(:execute) { service.execute(remote_mirror) }

    it 'destroys a push mirror' do
      expect { execute }.to change { project.remote_mirrors.count }.from(1).to(0)

      is_expected.to be_success
    end

    context 'when user does not have permissions' do
      let(:user) { nil }

      it 'returns an error' do
        expect { execute }.not_to change { RemoteMirror.count }

        is_expected.to be_error
        expect(execute.message).to eq('Access Denied')
      end
    end

    context 'when remote mirror is missing' do
      let(:remote_mirror) { nil }

      it 'returns an error' do
        is_expected.to be_error
        expect(execute.message).to eq('Remote mirror is missing')
      end
    end

    context 'when mirror does not match the project' do
      let!(:remote_mirror) { create(:remote_mirror) }

      it 'returns an error' do
        expect { execute }.not_to change { RemoteMirror.count }

        is_expected.to be_error
        expect(execute.message).to eq('Project mismatch')
      end
    end

    context 'when destroy process fails' do
      before do
        allow(remote_mirror).to receive(:destroy) do
          remote_mirror.errors.add(:base, 'destroy error')
        end.and_return(nil)
      end

      it 'returns an error' do
        expect { execute }.not_to change { RemoteMirror.count }

        is_expected.to be_error
        expect(execute.message.full_messages).to include('destroy error')
      end
    end
  end
end
