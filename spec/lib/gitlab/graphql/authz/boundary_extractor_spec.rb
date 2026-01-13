# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::BoundaryExtractor, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper
  using RSpec::Parameterized::TableSyntax

  let_it_be(:project) { create(:project) }
  let_it_be(:group) { create(:group) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:context) { {} }
  let(:object) { nil }
  let(:arguments) { {} }

  subject(:boundary_extractor) { described_class.new(object:, arguments:, context:, directive:) }

  shared_examples 'extracts project boundary' do
    it 'returns project boundary' do
      expect(boundary).to be_a(Authz::Boundary::ProjectBoundary)
      expect(boundary.namespace).to eq(project.project_namespace)
    end
  end

  shared_examples 'extracts group boundary' do
    it 'returns group boundary' do
      expect(boundary).to be_a(Authz::Boundary::GroupBoundary)
      expect(boundary.namespace).to eq(group)
    end
  end

  shared_examples 'extracts nil boundary' do
    it 'returns nil boundary' do
      expect(boundary).to be_a(Authz::Boundary::NilBoundary)
      expect(boundary.namespace).to be_nil
    end
  end

  shared_examples 'returns nil' do
    it 'returns nil' do
      expect(boundary).to be_nil
    end
  end

  describe '#extract' do
    subject(:boundary) { boundary_extractor.extract }

    context 'with boundary_argument in directive' do
      let(:directive) { create_directive(boundary_argument: 'arg') }

      where(method: [:to_global_id, :full_path])

      with_them do
        let(:arguments) { { arg: project.public_send(method) } }

        it_behaves_like 'extracts project boundary'
      end

      with_them do
        let(:arguments) { { arg: group.public_send(method) } }

        it_behaves_like 'extracts group boundary'
      end

      with_them do
        let(:arguments) { { input: { arg: project.public_send(method) } } }

        it_behaves_like 'extracts project boundary'
      end

      with_them do
        let(:arguments) { { input: { arg: group.public_send(method) } } }

        it_behaves_like 'extracts group boundary'
      end

      context 'with edge cases' do
        where(arguments: [{ arg: nil }, { arg: 'nonexistent/project' }, {}])

        with_them do
          it_behaves_like 'returns nil'
        end
      end
    end

    context 'with standalone boundaries' do
      context 'when boundary is user' do
        let(:directive) { create_directive(boundary: 'user') }
        let(:object) { issue }

        it_behaves_like 'extracts nil boundary'
      end

      context 'when boundary is instance' do
        let(:directive) { create_directive(boundary: 'instance') }
        let(:object) { issue }

        it_behaves_like 'extracts nil boundary'
      end
    end

    context 'with boundary method in directive' do
      let(:directive) { create_directive(boundary: 'project') }
      let(:object) { issue }

      it_behaves_like 'extracts project boundary'

      context 'when object matches the boundary type' do
        context 'with project boundary' do
          let(:object) { project }

          it_behaves_like 'extracts project boundary'
        end

        context 'with group boundary' do
          let(:directive) { create_directive(boundary: 'group') }
          let(:object) { group }

          it_behaves_like 'extracts group boundary'
        end
      end

      context 'when boundary method is invalid' do
        let(:directive) { create_directive(boundary: 'invalid_method') }

        it 'raises an error' do
          expect { boundary }.to raise_error(ArgumentError, /Invalid boundary method: 'invalid_method'/)
        end
      end

      context 'when boundary method does not exist' do
        let(:directive) { create_directive(boundary: 'nonexistent_method') }

        before do
          stub_const("#{described_class.name}::VALID_BOUNDARY_ACCESSOR_METHODS", ['nonexistent_method'])
        end

        it 'raises an error' do
          expect { boundary }.to raise_error(ArgumentError, /Boundary method 'nonexistent_method' not found/)
        end
      end

      context 'when boundary method returns nil' do
        before do
          allow(issue).to receive(:project).and_return(nil)
        end

        it_behaves_like 'returns nil'
      end
    end

    context 'when directive has neither boundary nor boundary_argument' do
      let(:directive) { create_directive }

      it_behaves_like 'returns nil'
    end

    context 'with ID fallback' do
      let(:directive) { create_directive(boundary: 'project') }

      context 'with GlobalID string' do
        let(:arguments) { { id: issue.to_global_id.to_s } }

        it_behaves_like 'extracts project boundary'
      end

      context 'with GlobalID object' do
        let(:arguments) { { id: issue.to_global_id } }

        it_behaves_like 'extracts project boundary'

        context 'when object is also provided' do
          let(:object) { issue }

          it_behaves_like 'extracts project boundary'
        end
      end

      context 'when GlobalID is invalid' do
        let(:arguments) { { id: 'invalid-gid' } }

        it_behaves_like 'returns nil'
      end

      context 'when GlobalID points to non-existent record' do
        let(:arguments) { { id: "gid://gitlab/Issue/999999999" } }

        it_behaves_like 'returns nil'
      end

      context 'when ID argument is not a GlobalID or string' do
        let(:arguments) { { id: 123 } }

        it 'raises an ArgumentError' do
          expect { boundary }.to raise_error(ArgumentError, 'ID argument must be a GlobalID or string')
        end
      end
    end

    context 'with wrapped GraphQL objects' do
      let(:directive) { create_directive(boundary: 'project') }
      let(:object) do
        instance_double(Types::BaseObject, object: issue).tap do |obj|
          allow(obj).to receive(:is_a?).with(Types::BaseObject).and_return(true)
        end
      end

      it_behaves_like 'extracts project boundary'
    end

    context 'when extracting boundary from resource objects' do
      let(:directive) { create_directive(boundary_argument: 'resource_id') }

      context 'when object has a project method' do
        let(:arguments) { { resource_id: issue.to_global_id } }

        it_behaves_like 'extracts project boundary'
      end

      context 'when object has a group method' do
        let_it_be(:label) { create(:group_badge, group:) }
        let(:arguments) { { resource_id: label.to_global_id } }

        it_behaves_like 'extracts group boundary'
      end

      context 'when object type has no project or group method' do
        let_it_be(:user) { create(:user) }
        let(:arguments) { { resource_id: user.to_global_id } }

        it_behaves_like 'returns nil'
      end
    end
  end
end
