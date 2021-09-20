# frozen_string_literal: true

require 'spec_helper'

RSpec.describe LooseForeignKey do
  let(:project_klass) do
    Class.new(ApplicationRecord) do
      include LooseForeignKey

      self.table_name = 'projects'

      loose_foreign_key :issues, :project_id, on_delete: :async_delete, gitlab_schema: :gitlab_main
      loose_foreign_key 'merge_requests', 'project_id', 'on_delete' => 'async_nullify', 'gitlab_schema' => :gitlab_main
    end
  end

  it 'exposes the loose foreign key definitions' do
    definitions = project_klass.loose_foreign_key_definitions

    tables = definitions.map(&:to_table)
    expect(tables).to eq(%w[issues merge_requests])
  end

  it 'casts strings to symbol' do
    definition = project_klass.loose_foreign_key_definitions.last

    expect(definition.from_table).to eq('projects')
    expect(definition.to_table).to eq('merge_requests')
    expect(definition.column).to eq('project_id')
    expect(definition.on_delete).to eq(:async_nullify)
    expect(definition.options[:gitlab_schema]).to eq(:gitlab_main)
  end

  context 'validation' do
    context 'on_delete validation' do
      let(:invalid_class) do
        Class.new(ApplicationRecord) do
          include LooseForeignKey

          self.table_name = 'projects'

          loose_foreign_key :issues, :project_id, on_delete: :async_delete, gitlab_schema: :gitlab_main
          loose_foreign_key :merge_requests, :project_id, on_delete: :async_nullify, gitlab_schema: :gitlab_main
          loose_foreign_key :merge_requests, :project_id, on_delete: :destroy, gitlab_schema: :gitlab_main
        end
      end

      it 'raises error when invalid `on_delete` option was given' do
        expect { invalid_class }.to raise_error /Invalid on_delete option given: destroy/
      end
    end

    context 'gitlab_schema validation' do
      let(:invalid_class) do
        Class.new(ApplicationRecord) do
          include LooseForeignKey

          self.table_name = 'projects'

          loose_foreign_key :merge_requests, :project_id, on_delete: :async_nullify, gitlab_schema: :unknown
        end
      end

      it 'raises error when invalid `gitlab_schema` option was given' do
        expect { invalid_class }.to raise_error /Invalid gitlab_schema option given: unknown/
      end
    end

    context 'inheritance validation' do
      let(:inherited_project_class) do
        Class.new(Project) do
          include LooseForeignKey

          loose_foreign_key :issues, :project_id, on_delete: :async_delete, gitlab_schema: :gitlab_main
        end
      end

      it 'raises error when loose_foreign_key is defined in a child ActiveRecord model' do
        expect { inherited_project_class }.to raise_error /Please define the loose_foreign_key on the Project class/
      end
    end
  end
end
