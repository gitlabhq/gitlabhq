# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Packages::Go::SyncPackagesService, feature_category: :package_registry do
  include_context 'basic Go module'

  let(:params) { { info: true, mod: true, zip: true } }

  describe '#execute_async' do
    it 'schedules a package refresh' do
      expect(::Packages::Go::SyncPackagesWorker).to receive(:perform_async).once

      described_class.new(project, 'master').execute_async
    end
  end

  describe '#initialize' do
    context 'without a project' do
      it 'raises an error' do
        expect { described_class.new(nil, 'master') }
          .to raise_error(ArgumentError, 'project is required')
      end
    end

    context 'without a ref' do
      it 'raises an error' do
        expect { described_class.new(project, nil) }
          .to raise_error(ArgumentError, 'ref is required')
      end
    end

    context 'with an invalid ref' do
      it 'raises an error' do
        expect { described_class.new(project, 'not-a-ref') }
        .to raise_error(ArgumentError)
      end
    end
  end
end
