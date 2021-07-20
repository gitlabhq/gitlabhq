# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::DestroyPackageService do
  let_it_be(:user) { create(:user) }

  let!(:package) { create(:npm_package) }

  describe '#execute' do
    subject(:service) { described_class.new(container: package, current_user: user) }

    context 'when the user is authorized' do
      before do
        package.project.add_maintainer(user)
      end

      context 'when the destroy is successfull' do
        it 'destroy the package' do
          expect(package).to receive(:sync_maven_metadata).and_call_original
          expect { service.execute }.to change { Packages::Package.count }.by(-1)
        end

        it 'returns a success ServiceResponse' do
          response = service.execute

          expect(response).to be_a(ServiceResponse)
          expect(response).to be_success
          expect(response.message).to eq("Package was successfully deleted")
        end
      end

      context 'when the destroy is not successful' do
        before do
          allow(package).to receive(:destroy!).and_raise(StandardError, "test")
        end

        it 'returns an error ServiceResponse' do
          response = service.execute

          expect(package).not_to receive(:sync_maven_metadata)
          expect(response).to be_a(ServiceResponse)
          expect(response).to be_error
          expect(response.message).to eq("Failed to remove the package")
          expect(response.status).to eq(:error)
        end
      end
    end

    context 'when the user is not authorized' do
      it 'returns an error ServiceResponse' do
        response = service.execute

        expect(response).to be_a(ServiceResponse)
        expect(response).to be_error
        expect(response.message).to eq("You don't have access to this package")
        expect(response.status).to eq(:error)
      end
    end
  end
end
