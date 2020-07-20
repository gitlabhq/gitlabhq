# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Checks::TagCheck do
  include_context 'change access checks context'

  describe '#validate!' do
    let(:ref) { 'refs/tags/v1.0.0' }

    it 'raises an error when user does not have access' do
      allow(user_access).to receive(:can_do_action?).with(:admin_tag).and_return(false)

      expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, 'You are not allowed to change existing tags on this project.')
    end

    context 'with protected tag' do
      let!(:protected_tag) { create(:protected_tag, project: project, name: 'v*') }

      context 'as maintainer' do
        before do
          project.add_maintainer(user)
        end

        context 'deletion' do
          let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
          let(:newrev) { '0000000000000000000000000000000000000000' }

          it 'is prevented' do
            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, /cannot be deleted/)
          end
        end

        context 'update' do
          let(:oldrev) { 'be93687618e4b132087f430a4d8fc3a609c9b77c' }
          let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }

          it 'is prevented' do
            expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, /cannot be updated/)
          end
        end
      end

      context 'creation' do
        let(:oldrev) { '0000000000000000000000000000000000000000' }
        let(:newrev) { '54fcc214b94e78d7a41a9a8fe6d87a5e59500e51' }
        let(:ref) { 'refs/tags/v9.1.0' }

        it 'prevents creation below access level' do
          expect { subject.validate! }.to raise_error(Gitlab::GitAccess::ForbiddenError, /allowed to create this tag as it is protected/)
        end

        context 'when user has access' do
          let!(:protected_tag) { create(:protected_tag, :developers_can_create, project: project, name: 'v*') }

          it 'allows tag creation' do
            expect { subject.validate! }.not_to raise_error
          end
        end
      end
    end
  end
end
