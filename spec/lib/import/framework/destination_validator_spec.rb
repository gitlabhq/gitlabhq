# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Import::Framework::DestinationValidator, feature_category: :importers do
  let_it_be(:current_user) { create(:user) }

  subject(:validator) { described_class.new(current_user: current_user) }

  describe '#validate_destination_namespace!' do
    context 'when destination_namespace is blank' do
      it 'does not raise an error' do
        expect { validator.validate_destination_namespace!(nil, 'group_entity') }.not_to raise_error
        expect { validator.validate_destination_namespace!('', 'group_entity') }.not_to raise_error
      end
    end

    context 'when the destination namespace does not exist' do
      it 'raises a BulkImports::Error' do
        expect { validator.validate_destination_namespace!('nonexistent/group', 'group_entity') }
          .to raise_error(
            ::BulkImports::Error,
            eq("Import failed. 'nonexistent/group' is invalid, or you do not have permission.")
          )
      end
    end

    context 'when the group exists' do
      let_it_be(:group) { create(:group) }
      let_it_be(:owned_group) { create(:group, owners: current_user) }

      context 'when source_type is group_entity' do
        context 'when the user can create subgroups' do
          it 'does not raise an error' do
            expect do
              validator.validate_destination_namespace!(
                owned_group.full_path, 'group_entity'
              )
            end.not_to raise_error
          end
        end

        context 'when the user cannot create subgroups' do
          it 'raises a BulkImports::Error' do
            expect do
              validator.validate_destination_namespace!(group.full_path, 'group_entity')
            end.to raise_error(
              ::BulkImports::Error,
              "Import failed. '#{group.full_path}' is invalid, or you do not have permission.")
          end
        end
      end

      context 'when source_type is project_entity' do
        context 'when the user can import projects' do
          it 'does not raise an error' do
            expect do
              validator.validate_destination_namespace!(owned_group.full_path, 'project_entity')
            end.not_to raise_error
          end
        end

        context 'when the user cannot import projects' do
          it 'raises a BulkImports::Error' do
            expect { validator.validate_destination_namespace!(group.full_path, 'project_entity') }
              .to raise_error(
                ::BulkImports::Error,
                "Import failed. '#{group.full_path}' is invalid, or you do not have permission.")
          end
        end
      end
    end
  end

  describe '#validate_destination_slug!' do
    context 'when the slug is valid' do
      it 'does not raise an error' do
        expect { validator.validate_destination_slug!('valid-slug') }.not_to raise_error
        expect { validator.validate_destination_slug!('valid_slug_123') }.not_to raise_error
      end
    end

    context 'when the slug is invalid' do
      it 'raises a BulkImports::Error' do
        expect { validator.validate_destination_slug!('destin-*-ation-slug') }
          .to raise_error(
            ::BulkImports::Error,
            "Import failed. The destination URL " \
              "can only include non-accented letters, digits, '_', '-' and '.'. " \
              "It must not start with '-', '_', or '.', nor end with '-', '_', '.', '.git', or '.atom'.")
      end
    end
  end

  describe '#validate_destination_full_path!' do
    context 'when source_type is group_entity' do
      context 'when no namespace exists at the full path' do
        it 'does not raise an error' do
          expect do
            validator.validate_destination_full_path!('some-group', 'new-slug', nil, 'group_entity')
          end.not_to raise_error
        end
      end

      context 'when a namespace already exists at the full path' do
        let_it_be(:group) { create(:group) }

        it 'raises a BulkImports::Error' do
          expect do
            validator.validate_destination_full_path!(group.parent&.full_path, group.path, nil, 'group_entity')
          end.to raise_error(
            ::BulkImports::Error,
            "Import failed. '#{group.full_path}' already exists. Change the destination and try again.")
        end
      end
    end

    context 'when source_type is project_entity' do
      context 'when no project exists at the full path' do
        it 'does not raise an error' do
          expect do
            validator.validate_destination_full_path!('some-group', 'new-project', nil, 'project_entity')
          end.not_to raise_error
        end
      end

      context 'when a project already exists at the full path' do
        let_it_be(:project) { create(:project) }

        it 'raises a BulkImports::Error' do
          expect do
            validator.validate_destination_full_path!(
              project.namespace.full_path, project.path, nil, 'project_entity'
            )
          end.to raise_error(
            ::BulkImports::Error,
            "Import failed. '#{project.full_path}' already exists. Change the destination and try again.")
        end
      end
    end

    context 'when source_type is invalid' do
      it 'raises an ArgumentError' do
        expect do
          validator.validate_destination_full_path!(
            'foo',
            'bar',
            nil,
            'invalid_source_type'
          )
        end.to raise_error(ArgumentError, 'source_type must be one of group_entity, project_entity')
      end
    end

    context 'when destination_slug is nil' do
      it 'falls back to destination_name' do
        expect do
          validator.validate_destination_full_path!('some-group', nil, 'new-name', 'project_entity')
        end.not_to raise_error
      end
    end

    context 'when destination_namespace is blank' do
      it 'builds full path from slug only' do
        expect do
          validator.validate_destination_full_path!(nil, 'some-slug', nil, 'project_entity')
        end.not_to raise_error
      end
    end
  end
end
