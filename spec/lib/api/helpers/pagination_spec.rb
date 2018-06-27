require 'spec_helper'

describe API::Helpers::Pagination do
  let(:resource) { Project.all }

  subject do
    Class.new.include(described_class).new
  end

  describe '#paginate (keyset pagination)' do
    let(:value) { spy('return value') }

    before do
      allow(value).to receive(:to_query).and_return(value)

      allow(subject).to receive(:header).and_return(value)
      allow(subject).to receive(:params).and_return(value)
      allow(subject).to receive(:request).and_return(value)
    end

    context 'when resource can be paginated' do
      let!(:projects) do
        [
          create(:project, name: 'One'),
          create(:project, name: 'Two'),
          create(:project, name: 'Three')
        ].sort_by { |e| -e.id } # sort by id desc (this is the default sort order for the API)
      end

      describe 'first page' do
        before do
          allow(subject).to receive(:params)
            .and_return({ pagination: 'keyset', per_page: 2 })
        end

        it 'returns appropriate amount of resources' do
          expect(subject.paginate(resource).count).to eq 2
        end

        it 'returns the first two records (by id desc)' do
          expect(subject.paginate(resource)).to eq(projects[0..1])
        end

        it 'adds appropriate headers' do
          expect_header('X-Per-Page', '2')
          expect_header('X-Next-Page', "#{value}?ks_prev_id=#{projects[1].id}&pagination=keyset&per_page=2")

          expect_header('Link', anything) do |_key, val|
            expect(val).to include('rel="next"')
          end

          subject.paginate(resource)
        end
      end

      describe 'second page' do
        before do
          allow(subject).to receive(:params)
            .and_return({ pagination: 'keyset', per_page: 2, ks_prev_id: projects[1].id })
        end

        it 'returns appropriate amount of resources' do
          expect(subject.paginate(resource).count).to eq 1
        end

        it 'returns the third record' do
          expect(subject.paginate(resource)).to eq(projects[2..2])
        end

        it 'adds appropriate headers' do
          expect_header('X-Per-Page', '2')
          expect_header('X-Next-Page', "#{value}?ks_prev_id=#{projects[2].id}&pagination=keyset&per_page=2")

          expect_header('Link', anything) do |_key, val|
            expect(val).to include('rel="next"')
          end

          subject.paginate(resource)
        end
      end

      describe 'third page' do
        before do
          allow(subject).to receive(:params)
            .and_return({ pagination: 'keyset', per_page: 2, ks_prev_id: projects[2].id })
        end

        it 'returns appropriate amount of resources' do
          expect(subject.paginate(resource).count).to eq 0
        end

        it 'adds appropriate headers' do
          expect_header('X-Per-Page', '2')
          expect(subject).not_to receive(:header).with('Link')

          subject.paginate(resource)
        end
      end

      context 'if order' do
        context 'is not present' do
          before do
            allow(subject).to receive(:params)
              .and_return({ pagination: 'keyset', per_page: 2 })
          end

          it 'is not present it adds default order(:id) desc' do
            resource.order_values = []

            paginated_relation = subject.paginate(resource)

            expect(resource.order_values).to be_empty
            expect(paginated_relation.order_values).to be_present
            expect(paginated_relation.order_values.size).to eq(1)
            expect(paginated_relation.order_values.first).to be_descending
            expect(paginated_relation.order_values.first.expr.name).to eq :id
          end
        end

        context 'is present' do
          let(:resource) { Project.all.order(name: :desc) }
          let!(:projects) do
            [
              create(:project, name: 'One'),
              create(:project, name: 'Two'),
              create(:project, name: 'Three'),
              create(:project, name: 'Three'), # Note the duplicate name
              create(:project, name: 'Four'),
              create(:project, name: 'Five'),
              create(:project, name: 'Six')
            ]

            # if we sort this by name descending, id descending, this yields:
            # {
            #   2 => "Two",
            #   4 => "Three",
            #   3 => "Three",
            #   7 => "Six",
            #   1 => "One",
            #   5 => "Four",
            #   6 => "Five"
            # }
            #
            # (key is the id)
          end

          it 'it also orders by primary key' do
            allow(subject).to receive(:params)
              .and_return({ pagination: 'keyset', per_page: 2 })
            paginated_relation = subject.paginate(resource)

            expect(paginated_relation.order_values).to be_present
            expect(paginated_relation.order_values.size).to eq(2)
            expect(paginated_relation.order_values.first).to be_descending
            expect(paginated_relation.order_values.first.expr.name).to eq :name
            expect(paginated_relation.order_values.second).to be_descending
            expect(paginated_relation.order_values.second.expr.name).to eq :id
          end

          it 'it returns the right records (first page)' do
            allow(subject).to receive(:params)
              .and_return({ pagination: 'keyset', per_page: 2 })
            result = subject.paginate(resource)

            expect(result.first).to eq(projects[1])
            expect(result.second).to eq(projects[3])
          end

          it 'it returns the right records (second page)' do
            allow(subject).to receive(:params)
              .and_return({ pagination: 'keyset', ks_prev_id: projects[3].id, ks_prev_name: projects[3].name, per_page: 2 })
            result = subject.paginate(resource)

            expect(result.first).to eq(projects[2])
            expect(result.second).to eq(projects[6])
          end

          it 'it returns the right records (third page), note increased per_page' do
            allow(subject).to receive(:params)
              .and_return({ pagination: 'keyset', ks_prev_id: projects[6].id, ks_prev_name: projects[6].name, per_page: 5 })
            result = subject.paginate(resource)

            expect(result.size).to eq(3)
            expect(result.first).to eq(projects[0])
            expect(result.second).to eq(projects[4])
            expect(result.last).to eq(projects[5])
          end

          it 'it returns the right link to the next page' do
            allow(subject).to receive(:params)
              .and_return({ pagination: 'keyset', ks_prev_id: projects[3].id, ks_prev_name: projects[3].name, per_page: 2 })
            expect_header('X-Per-Page', '2')
            expect_header('X-Next-Page', "#{value}?ks_prev_id=#{projects[6].id}&ks_prev_name=#{projects[6].name}&pagination=keyset&per_page=2")

            expect_header('Link', anything) do |_key, val|
              expect(val).to include('rel="next"')
            end

            subject.paginate(resource)
          end
        end
      end
    end
  end

  describe '#paginate (default offset-based pagination)' do
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
  end

  def expect_header(*args, &block)
    expect(subject).to receive(:header).with(*args, &block)
  end

  def expect_message(method)
    expect(subject).to receive(method)
      .at_least(:once).and_return(value)
  end
end
