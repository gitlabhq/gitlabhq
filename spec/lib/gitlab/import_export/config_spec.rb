# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::Config do
  let(:yaml_file) { described_class.new }

  describe '#to_h' do
    context 'when using CE' do
      before do
        allow(yaml_file)
          .to receive(:merge?)
          .and_return(false)
      end

      it 'just returns the parsed Hash without the EE section' do
        expected = YAML.load_file(Gitlab::ImportExport.config_file)
        expected.delete('ee')

        expect(yaml_file.to_h).to eq(expected)
      end
    end

    context 'when using EE' do
      before do
        allow(yaml_file)
          .to receive(:merge?)
          .and_return(true)
      end

      it 'merges the EE project tree into the CE project tree' do
        allow(yaml_file)
          .to receive(:parse_yaml)
          .and_return({
            'project_tree' => [
              {
                'issues' => [
                  :id,
                  :title,
                  { 'notes' => [:id, :note, { 'author' => [:name] }] }
                ]
              }
            ],
            'ee' => {
              'project_tree' => [
                {
                  'issues' => [
                    :description,
                    { 'notes' => [:date, { 'author' => [:email] }] }
                  ]
                },
                { 'foo' => [{ 'bar' => %i[baz] }] }
              ]
            }
          })

        expect(yaml_file.to_h).to eq({
          'project_tree' => [
            {
              'issues' => [
                :id,
                :title,
                {
                  'notes' => [
                    :id,
                    :note,
                    { 'author' => [:name, :email] },
                    :date
                  ]
                },
                :description
              ]
            },
            { 'foo' => [{ 'bar' => %i[baz] }] }
          ]
        })
      end

      it 'merges the excluded attributes list' do
        allow(yaml_file)
          .to receive(:parse_yaml)
          .and_return({
            'project_tree' => [],
            'excluded_attributes' => {
              'project' => %i[id title],
              'notes' => %i[id]
            },
            'ee' => {
              'project_tree' => [],
              'excluded_attributes' => {
                'project' => %i[date],
                'foo' => %i[bar baz]
              }
            }
          })

        expect(yaml_file.to_h).to eq({
          'project_tree' => [],
          'excluded_attributes' => {
            'project' => %i[id title date],
            'notes' => %i[id],
            'foo' => %i[bar baz]
          }
        })
      end

      it 'merges the included attributes list' do
        allow(yaml_file)
          .to receive(:parse_yaml)
          .and_return({
            'project_tree' => [],
            'included_attributes' => {
              'project' => %i[id title],
              'notes' => %i[id]
            },
            'ee' => {
              'project_tree' => [],
              'included_attributes' => {
                'project' => %i[date],
                'foo' => %i[bar baz]
              }
            }
          })

        expect(yaml_file.to_h).to eq({
          'project_tree' => [],
          'included_attributes' => {
            'project' => %i[id title date],
            'notes' => %i[id],
            'foo' => %i[bar baz]
          }
        })
      end

      it 'merges the methods list' do
        allow(yaml_file)
          .to receive(:parse_yaml)
          .and_return({
            'project_tree' => [],
            'methods' => {
              'project' => %i[id title],
              'notes' => %i[id]
            },
            'ee' => {
              'project_tree' => [],
              'methods' => {
                'project' => %i[date],
                'foo' => %i[bar baz]
              }
            }
          })

        expect(yaml_file.to_h).to eq({
          'project_tree' => [],
          'methods' => {
            'project' => %i[id title date],
            'notes' => %i[id],
            'foo' => %i[bar baz]
          }
        })
      end
    end
  end
end
