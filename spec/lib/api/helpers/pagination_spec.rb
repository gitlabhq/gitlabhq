require 'spec_helper'

describe API::Helpers::Pagination do
  let(:resource) { Project.all }

  subject do
    Class.new.include(described_class).new
  end

  describe '#paginate' do
    let(:value) { spy('return value') }

    before do
      allow(value).to receive(:to_query).and_return(value)

      allow(subject).to receive(:header).and_return(value)
      allow(subject).to receive(:params).and_return(value)
      allow(subject).to receive(:request).and_return(value)
    end

    describe 'required instance methods' do
      let(:return_spy) { spy }

      it 'requires some instance methods' do
        expect_message(:header)
        expect_message(:params)
        expect_message(:request)

        subject.paginate(resource)
      end
    end

    context 'when resource can be paginated' do
      before do
        create_list(:project, 3)
      end

      describe 'first page' do
        before do
          allow(subject).to receive(:params)
            .and_return({ page: 1, per_page: 2 })
        end

        it 'returns appropriate amount of resources' do
          expect(subject.paginate(resource).count).to eq 2
        end

        it 'adds appropriate headers' do
          expect_header('X-Total', '3')
          expect_header('X-Total-Pages', '2')
          expect_header('X-Per-Page', '2')
          expect_header('X-Page', '1')
          expect_header('X-Next-Page', '2')
          expect_header('X-Prev-Page', '')

          expect_header('Link', anything) do |_key, val|
            expect(val).to include('rel="first"')
            expect(val).to include('rel="last"')
            expect(val).to include('rel="next"')
            expect(val).not_to include('rel="prev"')
          end

          subject.paginate(resource)
        end
      end

      describe 'second page' do
        before do
          allow(subject).to receive(:params)
            .and_return({ page: 2, per_page: 2 })
        end

        it 'returns appropriate amount of resources' do
          expect(subject.paginate(resource).count).to eq 1
        end

        it 'adds appropriate headers' do
          expect_header('X-Total', '3')
          expect_header('X-Total-Pages', '2')
          expect_header('X-Per-Page', '2')
          expect_header('X-Page', '2')
          expect_header('X-Next-Page', '')
          expect_header('X-Prev-Page', '1')

          expect_header('Link', anything) do |_key, val|
            expect(val).to include('rel="first"')
            expect(val).to include('rel="last"')
            expect(val).to include('rel="prev"')
            expect(val).not_to include('rel="next"')
          end

          subject.paginate(resource)
        end
      end

      context 'if order' do
        it 'is not present it adds default order(:id) if no order is present' do
          resource.order_values = []

          paginated_relation = subject.paginate(resource)

          expect(resource.order_values).to be_empty
          expect(paginated_relation.order_values).to be_present
          expect(paginated_relation.order_values.first).to be_ascending
          expect(paginated_relation.order_values.first.expr.name).to eq :id
        end

        it 'is present it does not add anything' do
          paginated_relation = subject.paginate(resource.order(created_at: :desc))

          expect(paginated_relation.order_values).to be_present
          expect(paginated_relation.order_values.first).to be_descending
          expect(paginated_relation.order_values.first.expr.name).to eq :created_at
        end
      end
    end

    context 'when resource empty' do
      describe 'first page' do
        before do
          allow(subject).to receive(:params)
            .and_return({ page: 1, per_page: 2 })
        end

        it 'returns appropriate amount of resources' do
          expect(subject.paginate(resource).count).to eq 0
        end

        it 'adds appropriate headers' do
          expect_header('X-Total', '0')
          expect_header('X-Total-Pages', '1')
          expect_header('X-Per-Page', '2')
          expect_header('X-Page', '1')
          expect_header('X-Next-Page', '')
          expect_header('X-Prev-Page', '')

          expect_header('Link', anything) do |_key, val|
            expect(val).to include('rel="first"')
            expect(val).to include('rel="last"')
            expect(val).not_to include('rel="prev"')
            expect(val).not_to include('rel="next"')
            expect(val).not_to include('page=0')
          end

          subject.paginate(resource)
        end
      end
    end

    def expect_header(*args, &block)
      expect(subject).to receive(:header).with(*args, &block)
    end

    def expect_message(method)
      expect(subject).to receive(method)
        .at_least(:once).and_return(value)
    end
  end
end
