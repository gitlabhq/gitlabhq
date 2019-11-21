# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Kubernetes::KubectlCmd do
  describe '.delete' do
    it 'constructs string properly' do
      args = %w(resource_type type --flag-1 --flag-2)

      expected_command = 'kubectl delete resource_type type --flag-1 --flag-2'

      expect(described_class.delete(*args)).to eq expected_command
    end
  end

  describe '.apply_file' do
    context 'without optional args' do
      it 'requires filename to be present' do
        expect { described_class.apply_file(nil) }.to raise_error(ArgumentError, "filename is not present")
        expect { described_class.apply_file("  ") }.to raise_error(ArgumentError, "filename is not present")
      end

      it 'constructs string properly' do
        expected_command = 'kubectl apply -f filename'

        expect(described_class.apply_file('filename')).to eq expected_command
      end
    end

    context 'with optional args' do
      it 'constructs command properly with many args' do
        args = %w(arg-1 --flag-0-1 arg-2 --flag-0-2)

        expected_command = 'kubectl apply -f filename arg-1 --flag-0-1 arg-2 --flag-0-2'

        expect(described_class.apply_file('filename', *args)).to eq expected_command
      end

      it 'constructs command properly with single arg' do
        args = "arg-1"

        expected_command = 'kubectl apply -f filename arg-1'

        expect(described_class.apply_file('filename', args)).to eq(expected_command)
      end
    end
  end

  describe '.api_resources' do
    it 'constructs string properly' do
      expected_command = 'kubectl api-resources -o name --api-group foo'

      expect(described_class.api_resources("-o", "name", "--api-group", "foo")).to eq expected_command
    end
  end

  describe '.delete_crds_from_group' do
    it 'constructs string properly' do
      expected_command = 'kubectl api-resources -o name --api-group foo | xargs kubectl delete --ignore-not-found crd'

      expect(described_class.delete_crds_from_group("foo")).to eq expected_command
    end
  end
end
