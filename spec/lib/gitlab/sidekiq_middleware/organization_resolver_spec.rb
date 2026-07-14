# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::SidekiqMiddleware::OrganizationResolver, feature_category: :organization do
  let_it_be(:organization) { create(:organization) }

  describe '.resolve' do
    let(:worker_class) do
      Class.new do
        def self.name
          'TestWorkerClassMethodDelegation'
        end

        include ApplicationWorker
      end
    end

    let(:args) { [] }

    it 'delegates to a new instance' do
      instance = instance_double(described_class, resolve: described_class::UNRESOLVED)

      expect(described_class).to receive(:new).with(worker_class, args).and_return(instance)
      expect(described_class.resolve(worker_class, args)).to eq(described_class::UNRESOLVED)
    end
  end

  describe '#resolve' do
    subject(:resolver) { described_class.new(worker_class, args) }

    let(:args) { [] }

    context 'when the worker does not implement organization_for_arguments' do
      let(:worker_class) do
        Class.new do
          def self.name
            'TestWorkerWithoutOrgMethod'
          end

          include ApplicationWorker
        end
      end

      it 'returns :unresolved' do
        expect(resolver.resolve).to eq(described_class::UNRESOLVED)
      end
    end

    context 'when the worker implements organization_for_arguments' do
      context 'and it returns an Organizations::Organization' do
        let(:worker_class) do
          org = organization

          Class.new do
            def self.name
              'TestWorkerReturningOrg'
            end

            include ApplicationWorker

            define_singleton_method(:organization_for_arguments) do |_args|
              org
            end
          end
        end

        it 'returns the organization' do
          expect(resolver.resolve).to eq(organization)
        end
      end

      context 'and it returns :cross_org' do
        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerCrossOrg'
            end

            include ApplicationWorker

            def self.organization_for_arguments(_args)
              :cross_org
            end
          end
        end

        it 'returns :cross_org' do
          expect(resolver.resolve).to eq(described_class::CROSS_ORG)
        end
      end

      context 'and it returns :unresolved' do
        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerUnresolved'
            end

            include ApplicationWorker

            def self.organization_for_arguments(_args)
              :unresolved
            end
          end
        end

        it 'returns :unresolved' do
          expect(resolver.resolve).to eq(described_class::UNRESOLVED)
        end
      end

      context 'and it returns an invalid value' do
        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerInvalidReturn'
            end

            include ApplicationWorker

            def self.organization_for_arguments(_args)
              'not-a-valid-return-value'
            end
          end
        end

        it 'raises ArgumentError' do
          expect { resolver.resolve }.to raise_error(
            ArgumentError,
            /must return an Organizations::Organization, :cross_org, or :unresolved/
          )
        end
      end

      context 'and it returns nil (invalid)' do
        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerNilReturn'
            end

            include ApplicationWorker

            def self.organization_for_arguments(_args)
              nil
            end
          end
        end

        it 'raises ArgumentError' do
          expect { resolver.resolve }.to raise_error(
            ArgumentError,
            /must return an Organizations::Organization, :cross_org, or :unresolved/
          )
        end
      end

      context 'and it uses the args to look up the organization by organization_id' do
        let(:args) { [organization.id] }

        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerWithOrgId'
            end

            include ApplicationWorker

            def self.organization_for_arguments(args)
              org_id = args.first
              ::Organizations::Organization.find_by_id(org_id) || :unresolved
            end
          end
        end

        it 'returns the organization found by id' do
          expect(resolver.resolve).to eq(organization)
        end

        context 'when the organization does not exist' do
          let(:args) { [non_existing_record_id] }

          it 'returns :unresolved (as implemented by the worker)' do
            expect(resolver.resolve).to eq(described_class::UNRESOLVED)
          end
        end
      end

      context 'and it uses a project_id arg to derive the organization' do
        let_it_be(:project) { create(:project, organization: organization) }
        let(:args) { [project.id] }

        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerWithProjectId'
            end

            include ApplicationWorker

            def self.organization_for_arguments(args)
              project_id = args.first
              project = Project.find_by_id(project_id)
              return :unresolved unless project

              project.organization || :unresolved
            end
          end
        end

        it 'returns the organization derived from the project' do
          expect(resolver.resolve).to eq(organization)
        end
      end

      context 'and it uses a namespace_id arg to derive the organization' do
        let_it_be(:group) { create(:group, organization: organization) }
        let(:args) { [group.id] }

        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerWithNamespaceId'
            end

            include ApplicationWorker

            def self.organization_for_arguments(args)
              namespace_id = args.first
              namespace = Namespace.find_by_id(namespace_id)
              return :unresolved unless namespace

              namespace.organization || :unresolved
            end
          end
        end

        it 'returns the organization derived from the namespace' do
          expect(resolver.resolve).to eq(organization)
        end
      end

      context 'and it raises an exception' do
        let(:worker_class) do
          Class.new do
            def self.name
              'TestWorkerRaisingError'
            end

            include ApplicationWorker

            def self.organization_for_arguments(_args)
              raise ActiveRecord::RecordNotFound, 'not found'
            end
          end
        end

        it 'propagates the exception (the resolver does not rescue worker errors)' do
          expect { resolver.resolve }.to raise_error(ActiveRecord::RecordNotFound)
        end
      end
    end
  end

  describe 'constants' do
    it 'exposes CROSS_ORG sentinel' do
      expect(described_class::CROSS_ORG).to eq(:cross_org)
    end

    it 'exposes UNRESOLVED sentinel' do
      expect(described_class::UNRESOLVED).to eq(:unresolved)
    end
  end
end
