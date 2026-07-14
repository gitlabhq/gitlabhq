# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Graphql::Authz::BoundaryExtractor, feature_category: :permissions do
  include Authz::GranularTokenAuthorizationHelper

  let_it_be(:group) { create(:group) }
  let_it_be(:project) { create(:project, group: group) }
  let_it_be(:issue) { create(:issue, project: project) }

  let(:object) { nil }
  let(:arguments) { nil }

  subject(:extractor) { described_class.new(directives, object: object, arguments: arguments) }

  describe '#extract' do
    subject(:extracted) { extractor.extract }

    context 'with object-sourced directives' do
      context 'when the boundary is :itself' do
        let(:object) { project }
        let(:directives) { [create_directive(boundary: 'itself', boundary_type: 'project')] }

        it 'returns the object itself' do
          expect(extracted).to contain_exactly(project)
        end
      end

      context 'when the boundary is a method on the object' do
        let(:object) { issue }
        let(:directives) { [create_directive(boundary: 'project', boundary_type: 'project')] }

        it 'returns the result of calling the method' do
          expect(extracted).to contain_exactly(project)
        end
      end

      context 'when the resolved boundary does not match the declared boundary_type' do
        let(:object) { issue }
        let(:directives) { [create_directive(boundary: 'project', boundary_type: 'group')] }

        it 'skips the boundary' do
          expect(extracted).to be_empty
        end
      end

      context 'when the object does not respond to the boundary method' do
        let(:object) { project }
        let(:directives) { [create_directive(boundary: 'nonexistent_method', boundary_type: 'project')] }

        it 'returns no boundary' do
          expect(extracted).to be_empty
        end
      end

      context 'when the boundary method returns nil' do
        let_it_be(:personal_project) { create(:project) }

        let(:object) { personal_project }
        let(:directives) { [create_directive(boundary: 'group', boundary_type: 'group')] }

        it 'returns no boundary' do
          expect(extracted).to be_empty
        end
      end

      context 'when the directive has no boundary method' do
        let(:object) { issue }
        let(:directives) { [create_directive(boundary_type: 'project')] }

        it 'returns no boundary instead of raising' do
          expect { extracted }.not_to raise_error
          expect(extracted).to be_empty
        end
      end

      context 'when the object is nil' do
        let(:directives) { [create_directive(boundary: 'itself', boundary_type: 'project')] }

        it 'returns no boundary' do
          expect(extracted).to be_empty
        end
      end
    end

    context 'with argument-sourced directives' do
      context 'when the boundary argument is a GlobalID for a project' do
        let(:directives) { [create_directive(boundary_argument: 'project_id', boundary_type: 'project')] }
        let(:arguments) { { project_id: project.to_global_id } }

        it 'locates and returns the project' do
          expect(extracted).to contain_exactly(project)
        end
      end

      context 'when the boundary argument is a full path string' do
        let(:directives) { [create_directive(boundary_argument: 'project_path', boundary_type: 'project')] }
        let(:arguments) { { project_path: project.full_path } }

        it 'locates and returns the project' do
          expect(extracted).to contain_exactly(project)
        end
      end

      context 'when the boundary argument resolves to a group' do
        let(:directives) { [create_directive(boundary_argument: 'group_path', boundary_type: 'group')] }
        let(:arguments) { { group_path: group.full_path } }

        it 'locates and returns the group' do
          expect(extracted).to contain_exactly(group)
        end
      end

      context 'when the located record is neither a project nor a group' do
        let(:directives) do
          [create_directive(boundary_argument: 'id', boundary: 'project', boundary_type: 'project')]
        end

        let(:arguments) { { id: issue.to_global_id } }

        it 'calls the boundary method on the located record' do
          expect(extracted).to contain_exactly(project)
        end
      end

      context 'when the directive has no boundary method and the record is not a project or group' do
        let(:directives) { [create_directive(boundary_argument: 'id', boundary_type: 'project')] }
        let(:arguments) { { id: issue.to_global_id } }

        it 'returns no boundary instead of raising' do
          expect { extracted }.not_to raise_error
          expect(extracted).to be_empty
        end
      end

      context 'when the argument value is nil' do
        let(:directives) { [create_directive(boundary_argument: 'project_id', boundary_type: 'project')] }
        let(:arguments) { { project_id: nil } }

        it 'returns no boundary' do
          expect(extracted).to be_empty
        end
      end

      context 'when the full path does not match a project or group' do
        let(:directives) { [create_directive(boundary_argument: 'project_path', boundary_type: 'project')] }
        let(:arguments) { { project_path: 'nonexistent/path' } }

        it 'returns no boundary' do
          expect(extracted).to be_empty
        end
      end

      context 'when the GlobalID points to a non-existent record' do
        let(:directives) { [create_directive(boundary_argument: 'project_id', boundary_type: 'project')] }
        let(:arguments) { { project_id: GlobalID.parse("gid://gitlab/Project/#{non_existing_record_id}") } }

        it 'returns no boundary' do
          expect(extracted).to be_empty
        end
      end

      context 'when the resolved boundary does not match the declared boundary_type' do
        let(:directives) { [create_directive(boundary_argument: 'project_path', boundary_type: 'group')] }
        let(:arguments) { { project_path: project.full_path } }

        it 'skips the directive' do
          expect(extracted).to be_empty
        end
      end

      context 'when the arguments are nil' do
        let(:directives) { [create_directive(boundary_argument: 'project_path', boundary_type: 'project')] }

        it 'returns no boundary' do
          expect(extracted).to be_empty
        end
      end
    end

    context 'when a directive declares a boundary_argument and only an object is available' do
      let(:object) { issue }
      let(:directives) do
        [create_directive(boundary_argument: 'project_path', boundary: 'project', boundary_type: 'project')]
      end

      it 'does not fall back to the object' do
        expect(extracted).to be_empty
      end
    end

    context 'when directives read from both sources' do
      let(:object) { issue }
      let(:arguments) { { group_path: group.full_path } }
      let(:directives) do
        [
          create_directive(boundary: 'project', boundary_type: 'project'),
          create_directive(boundary_argument: 'group_path', boundary_type: 'group')
        ]
      end

      it 'extracts each boundary from its declared source' do
        expect(extracted).to contain_exactly(project, group)
      end
    end

    context 'with a standalone boundary' do
      let(:object) { issue }
      let(:directives) { [create_directive(boundary_type: 'user')] }

      it 'returns the boundary_type symbol' do
        expect(extracted).to contain_exactly(:user)
      end
    end

    context 'with both a concrete and a standalone boundary directive' do
      let(:object) { project }
      let(:directives) do
        [
          create_directive(boundary: 'itself', boundary_type: 'project'),
          create_directive(boundary_type: 'instance')
        ]
      end

      it 'prefers the concrete boundary over the standalone one' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'when the concrete boundary does not match and a standalone boundary is present' do
      let(:object) { project }
      let(:directives) do
        [
          create_directive(boundary: 'itself', boundary_type: 'group'),
          create_directive(boundary_type: 'instance')
        ]
      end

      it 'falls back to the standalone boundary' do
        expect(extracted).to contain_exactly(:instance)
      end
    end

    context 'when an argument-sourced concrete boundary is present alongside a standalone directive' do
      let(:arguments) { { project_path: project.full_path } }
      let(:directives) do
        [
          create_directive(boundary_argument: 'project_path', boundary_type: 'project'),
          create_directive(boundary_type: 'instance')
        ]
      end

      it 'prefers the concrete boundary over the standalone one' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'with duplicate concrete boundary directives' do
      let(:object) { project }
      let(:directives) do
        [
          create_directive(boundary: 'itself', boundary_type: 'project'),
          create_directive(boundary: 'itself', boundary_type: 'project')
        ]
      end

      it 'de-duplicates the resolved resources' do
        expect(extracted).to contain_exactly(project)
      end
    end

    context 'with duplicate standalone boundary directives' do
      let(:directives) do
        [
          create_directive(boundary_type: 'instance'),
          create_directive(boundary_type: 'instance')
        ]
      end

      it 'de-duplicates the boundary_type symbols' do
        expect(extracted).to contain_exactly(:instance)
      end
    end

    context 'when there are no directives' do
      let(:object) { project }
      let(:arguments) { { project_path: project.full_path } }
      let(:directives) { [] }

      it 'returns an empty array' do
        expect(extracted).to eq([])
      end
    end
  end
end
