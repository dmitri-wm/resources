require_relative '../spec_helper'

RSpec.describe Resources::Associations::ThroughIdentifier do
  let(:source) { double('source') }
  let(:through_assoc_name) { :children }
  let(:target_assoc_name) { :parent }

  describe '.[]' do
    context 'when through_assoc_name is present' do
      it 'creates a new instance' do
        result = nil
        described_class[source, through_assoc_name, target_assoc_name] { |r| result = r }
        expect(result).to be_a(described_class)
      end
    end

    context 'when through_assoc_name is nil' do
      it 'returns nil' do
        result = described_class[source, target_assoc_name, nil]
        expect(result).to be_nil
      end
    end
  end

  describe '#join_relation' do
    let(:join_relation) { double('join_relation') }
    subject { described_class.new(source, through_assoc_name, target_assoc_name) }

    context 'when association exists' do
      it 'returns the join relation' do
        expect(source).to receive(:associations).and_return({ children: join_relation })
        expect(subject.join_relation).to eq(join_relation)
      end
    end

    context 'when association does not exist' do
      it 'raises an ArgumentError' do
        expect(source).to receive(:associations).and_return({})
        expect { subject.join_relation }.to raise_error(ArgumentError, "Association children not found on #{source}")
      end
    end
  end

  describe '#target_relation' do
    let(:join_relation) { double('join_relation') }
    let(:target_relation) { double('target_relation') }
    subject { described_class.new(source, through_assoc_name, target_assoc_name) }

    context 'when association exists' do
      it 'returns the target relation' do
        expect(subject).to receive(:join_relation).and_return(join_relation)
        expect(join_relation).to receive(:associations).and_return({ parent: target_relation })
        expect(subject.target_relation).to eq(target_relation)
      end
    end

    context 'when association does not exist' do
      it 'raises an ArgumentError' do
        expect(subject).to receive(:join_relation).and_return(join_relation)
        expect(join_relation).to receive(:associations).and_return({})
        expect { subject.target_relation }.to raise_error(ArgumentError, 'Association parent not found on children')
      end
    end
  end

  describe '#to_sym' do
    it 'returns the source name as a symbol' do
      expect(source).to receive(:name).and_return('SourceName')
      subject = described_class.new(source, through_assoc_name, target_assoc_name)
      expect(subject.to_sym).to eq(:SourceName)
    end
  end
end
