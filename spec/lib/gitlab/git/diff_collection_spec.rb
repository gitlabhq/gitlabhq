require 'spec_helper'

describe Gitlab::Git::DiffCollection, seed_helper: true do
  subject do
    Gitlab::Git::DiffCollection.new(
      iterator,
      max_files: max_files,
      max_lines: max_lines,
      limits: limits,
      expanded: expanded
    )
  end
  let(:iterator) { MutatingConstantIterator.new(file_count, fake_diff(line_length, line_count)) }
  let(:file_count) { 0 }
  let(:line_length) { 1 }
  let(:line_count) { 1 }
  let(:max_files) { 10 }
  let(:max_lines) { 100 }
  let(:limits) { true }
  let(:expanded) { true }

  describe '#to_a' do
    subject { super().to_a }
    it { is_expected.to be_kind_of ::Array }
  end

  describe '#decorate!' do
    let(:file_count) { 3 }

    it 'modifies the array in place' do
      count = 0
      subject.decorate! { |d| !d.nil? && count += 1 }
      expect(subject.to_a).to eq([1, 2, 3])
      expect(count).to eq(3)
    end

    it 'avoids future iterator iterations' do
      subject.decorate! { |d| d unless d.nil? }

      expect(iterator).not_to receive(:each)

      subject.overflow?
    end
  end

  context 'overflow handling' do
    context 'adding few enough files' do
      let(:file_count) { 3 }

      context 'and few enough lines' do
        let(:line_count) { 10 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('3') }
        end

        describe '#size' do
          it { expect(subject.size).to eq(3) }

          it 'does not change after peeking' do
            subject.any?
            expect(subject.size).to eq(3)
          end
        end

        context 'when limiting is disabled' do
          let(:limits) { false }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('3') }
          end

          describe '#size' do
            it { expect(subject.size).to eq(3) }

            it 'does not change after peeking' do
              subject.any?
              expect(subject.size).to eq(3)
            end
          end
        end
      end

      context 'and too many lines' do
        let(:line_count) { 1000 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('0+') }
        end
        it { expect(subject.size).to eq(0) }

        context 'when limiting is disabled' do
          let(:limits) { false }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('3') }
          end
          it { expect(subject.size).to eq(3) }
        end
      end
    end

    context 'adding too many files' do
      let(:file_count) { 11 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('10+') }
        end
        it { expect(subject.size).to eq(10) }

        context 'when limiting is disabled' do
          let(:limits) { false }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('11') }
          end
          it { expect(subject.size).to eq(11) }
        end
      end

      context 'and too many lines' do
        let(:line_count) { 30 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_truthy }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('3+') }
        end
        it { expect(subject.size).to eq(3) }

        context 'when limiting is disabled' do
          let(:limits) { false }

          describe '#overflow?' do
            subject { super().overflow? }
            it { is_expected.to be_falsey }
          end

          describe '#empty?' do
            subject { super().empty? }
            it { is_expected.to be_falsey }
          end

          describe '#real_size' do
            subject { super().real_size }
            it { is_expected.to eq('11') }
          end
          it { expect(subject.size).to eq(11) }
        end
      end
    end

    context 'adding exactly the maximum number of files' do
      let(:file_count) { 10 }

      context 'and few enough lines' do
        let(:line_count) { 1 }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('10') }
        end
        it { expect(subject.size).to eq(10) }
      end
    end

    context 'adding too many bytes' do
      let(:file_count) { 10 }
      let(:line_length) { 5200 }

      describe '#overflow?' do
        subject { super().overflow? }
        it { is_expected.to be_truthy }
      end

      describe '#empty?' do
        subject { super().empty? }
        it { is_expected.to be_falsey }
      end

      describe '#real_size' do
        subject { super().real_size }
        it { is_expected.to eq('9+') }
      end
      it { expect(subject.size).to eq(9) }

      context 'when limiting is disabled' do
        let(:limits) { false }

        describe '#overflow?' do
          subject { super().overflow? }
          it { is_expected.to be_falsey }
        end

        describe '#empty?' do
          subject { super().empty? }
          it { is_expected.to be_falsey }
        end

        describe '#real_size' do
          subject { super().real_size }
          it { is_expected.to eq('10') }
        end
        it { expect(subject.size).to eq(10) }
      end
    end
  end

  describe 'empty collection' do
    subject { Gitlab::Git::DiffCollection.new([]) }

    describe '#overflow?' do
      subject { super().overflow? }
      it { is_expected.to be_falsey }
    end

    describe '#empty?' do
      subject { super().empty? }
      it { is_expected.to be_truthy }
    end

    describe '#size' do
      subject { super().size }
      it { is_expected.to eq(0) }
    end

    describe '#real_size' do
      subject { super().real_size }
      it { is_expected.to eq('0')}
    end
  end

  describe '#each' do
    context 'when diff are too large' do
      let(:collection) do
        Gitlab::Git::DiffCollection.new([{ diff: 'a' * 204800 }])
      end

      it 'yields Diff instances even when they are too large' do
        expect { |b| collection.each(&b) }
          .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
      end

      it 'prunes diffs that are too large' do
        diff = nil

        collection.each do |d|
          diff = d
        end

        expect(diff.diff).to eq('')
      end
    end

    context 'when diff is quite large will collapse by default' do
      let(:iterator) { [{ diff: 'a' * 20480 }] }

      context 'when no collapse is set' do
        let(:expanded) { true }

        it 'yields Diff instances even when they are quite big' do
          expect { |b| subject.each(&b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
        end

        it 'does not prune diffs' do
          diff = nil

          subject.each do |d|
            diff = d
          end

          expect(diff.diff).not_to eq('')
        end
      end

      context 'when no collapse is unset' do
        let(:expanded) { false }

        it 'yields Diff instances even when they are quite big' do
          expect { |b| subject.each(&b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
        end

        it 'prunes diffs that are quite big' do
          diff = nil

          subject.each do |d|
            diff = d
          end

          expect(diff.diff).to eq('')
        end

        context 'when go over safe limits on files' do
          let(:iterator) { [fake_diff(1, 1)] * 4 }

          before do
            stub_const('Gitlab::Git::DiffCollection::DEFAULT_LIMITS', { max_files: 2, max_lines: max_lines })
          end

          it 'prunes diffs by default even little ones' do
            subject.each_with_index do |d, i|
              if i < 2
                expect(d.diff).not_to eq('')
              else # 90 lines
                expect(d.diff).to eq('')
              end
            end
          end
        end

        context 'when go over safe limits on lines' do
          let(:iterator) do
            [
              fake_diff(1, 45),
              fake_diff(1, 45),
              fake_diff(1, 20480),
              fake_diff(1, 1)
            ]
          end

          before do
            stub_const('Gitlab::Git::DiffCollection::DEFAULT_LIMITS', { max_files: max_files, max_lines: 80 })
          end

          it 'prunes diffs by default even little ones' do
            subject.each_with_index do |d, i|
              if i < 2
                expect(d.diff).not_to eq('')
              else # 90 lines
                expect(d.diff).to eq('')
              end
            end
          end
        end

        context 'when go over safe limits on bytes' do
          let(:iterator) do
            [
              fake_diff(1, 45),
              fake_diff(1, 45),
              fake_diff(1, 20480),
              fake_diff(1, 1)
            ]
          end

          before do
            stub_const('Gitlab::Git::DiffCollection::DEFAULT_LIMITS', { max_files: max_files, max_lines: 80 })
          end

          it 'prunes diffs by default even little ones' do
            subject.each_with_index do |d, i|
              if i < 2
                expect(d.diff).not_to eq('')
              else # > 80 bytes
                expect(d.diff).to eq('')
              end
            end
          end
        end
      end

      context 'when limiting is disabled' do
        let(:limits) { false }

        it 'yields Diff instances even when they are quite big' do
          expect { |b| subject.each(&b) }
            .to yield_with_args(an_instance_of(Gitlab::Git::Diff))
        end

        it 'does not prune diffs' do
          diff = nil

          subject.each do |d|
            diff = d
          end

          expect(diff.diff).not_to eq('')
        end
      end
    end
  end

  def fake_diff(line_length, line_count)
    { 'diff' => "#{'a' * line_length}\n" * line_count }
  end

  class MutatingConstantIterator
    include Enumerable

    def initialize(count, value)
      @count = count
      @value = value
    end

    def each
      return enum_for(:each) unless block_given?

      loop do
        break if @count.zero?

        # It is critical to decrement before yielding. We may never reach the lines after 'yield'.
        @count -= 1
        yield @value
      end
    end
  end
end
