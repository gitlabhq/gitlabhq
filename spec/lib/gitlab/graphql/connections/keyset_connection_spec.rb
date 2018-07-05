require 'spec_helper'

describe Gitlab::Graphql::Connections::KeysetConnection do
  let(:nodes) { Project.all.order(id: :asc) }
  let(:arguments) {  {} }
  subject(:connection) do
    described_class.new(nodes, arguments, max_page_size: 3)
  end

  def encoded_property(value)
    Base64.strict_encode64(value.to_s)
  end

  describe '#cursor_from_nodes' do
    let(:project) { create(:project) }

    it 'returns an encoded ID' do
      expect(connection.cursor_from_node(project))
        .to eq(encoded_property(project.id))
    end

    context 'when an order was specified' do
      let(:nodes) { Project.order(:updated_at) }

      it 'returns the encoded value of the order' do
        expect(connection.cursor_from_node(project))
          .to eq(encoded_property(project.updated_at))
      end
    end
  end

  describe '#sliced_nodes' do
    let(:projects) { create_list(:project, 4) }

    context 'when before is passed' do
      let(:arguments) { { before: encoded_property(projects[1].id) } }

      it 'only returns the project before the selected one' do
        expect(subject.sliced_nodes).to contain_exactly(projects.first)
      end

      context 'when the sort order is descending' do
        let(:nodes) { Project.all.order(id: :desc) }

        it 'returns the correct nodes' do
          expect(subject.sliced_nodes).to contain_exactly(*projects[2..-1])
        end
      end
    end

    context 'when after is passed' do
      let(:arguments) { { after: encoded_property(projects[1].id) } }

      it 'only returns the project before the selected one' do
        expect(subject.sliced_nodes).to contain_exactly(*projects[2..-1])
      end

      context 'when the sort order is descending' do
        let(:nodes) { Project.all.order(id: :desc) }

        it 'returns the correct nodes' do
          expect(subject.sliced_nodes).to contain_exactly(projects.first)
        end
      end
    end

    context 'when both before and after are passed' do
      let(:arguments) do
        {
          after: encoded_property(projects[1].id),
          before: encoded_property(projects[3].id)
        }
      end

      it 'returns the expected set' do
        expect(subject.sliced_nodes).to contain_exactly(projects[2])
      end
    end
  end

  describe '#paged_nodes' do
    let!(:projects) { create_list(:project, 5) }

    it 'returns the collection limited to max page size' do
      expect(subject.paged_nodes.size).to eq(3)
    end

    context 'when `first` is passed' do
      let(:arguments) { { first: 2 } }

      it 'returns only the first elements' do
        expect(subject.paged_nodes).to contain_exactly(projects.first, projects.second)
      end
    end

    context 'when `last` is passed' do
      let(:arguments) { { last: 2 } }

      it 'returns only the last elements' do
        expect(subject.paged_nodes).to contain_exactly(projects[3], projects[4])
      end
    end

    context 'when both are passed' do
      let(:arguments) { { first: 2, last: 2 } }

      it 'raises an error' do
        expect { subject.paged_nodes }.to raise_error(Gitlab::Graphql::Errors::ArgumentError)
      end
    end
  end
end
