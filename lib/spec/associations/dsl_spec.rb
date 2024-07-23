# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Resources::Associations::Dsl do
  let(:test_class) do
    Class.new do
      include Resources::Associations::Dsl
    end
  end

  before do
    Module.new do
      class << self
        def call(*_)
          yield Class.new
        end
        alias_method :[], :call
      end
    end.then do |klass|
      stub_const('Resources::Associations::TargetIdentifier', klass)
    end
  end

  describe '.associate' do
    it 'defines association methods' do
      test_class.class_eval do
        associate do
          has_many :posts
          belongs_to :company
        end
      end

      instance = test_class.new
      expect(instance).to respond_to(:posts)
      expect(instance).to respond_to(:company)
      expect(instance).to respond_to(:companies)
    end
  end

  describe Resources::Associations::Dsl::DSL do
    let(:source) { double('source') }
    subject { described_class.new(source) }

    describe '#has_many' do
      context 'without through option' do
        it 'adds a HasMany association' do
          expect(Resources::Associations::Definitions::HasMany).to receive(:new).with(source: source, relation: :PostRelation, name: :posts).and_return(double('association', name: :posts))
          subject.has_many(:posts, relation: :PostRelation)
        end
      end

      context 'with through option' do
        it 'adds a HasManyThrough association' do
          expect(Resources::Associations::Definitions::HasManyThrough).to receive(:new).with(source: source, through: :comments, name: :posts).and_return(double('association', name: :posts))
          subject.has_many(:posts, through: :comments)
        end
      end
    end
    describe '#belongs_to' do
      it 'adds a BelongsTo association' do
        expect(Resources::Associations::Definitions::BelongsTo).to receive(:new).with(source: source, relation: :company, name: :company).and_return(double('association', name: :company))
        subject.belongs_to(:company, relation: :company)
      end
    end
    describe '#has_one' do
      context 'without through option' do
        it 'adds a HasOne association' do
          expect(Resources::Associations::Definitions::HasOne).to receive(:new).with(source: source, relation: :profile, name: :profile).and_return(double('association', name: :profile))
          subject.has_one(:profile, relation: :profile)
        end
      end

      context 'with through option' do
        it 'adds a HasOneThrough association' do
          expect(Resources::Associations::Definitions::HasOneThrough).to receive(:new).with(source: source, relation: :avatar, name: :avatar, through: :profile).and_return(double('association', name: :avatar))
          subject.has_one(:avatar, relation: :avatar, through: :profile)
        end
      end
    end
  end
end
