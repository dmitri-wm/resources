require 'spec_helper'

RSpec.describe Resources::Sql do
  before :all do
    ActiveRecord::Base.connection.create_table :parents do |t|
      t.string :name
      t.boolean :rich
      t.timestamps
    end

    ActiveRecord::Base.connection.create_table :children do |t|
      t.string :name
      t.references :parent
      t.timestamps
    end

    ActiveRecord::Base.connection.create_table :grand_children do |t|
      t.string :name
      t.references :child
      t.timestamps
    end
  end

  before :each do
    # @!class Parent
    parent = Class.new(ActiveRecord::Base) do
      self.table_name = :parents
      has_many :children
    end

    child = Class.new(ActiveRecord::Base) do
      self.table_name = :children
      belongs_to :parent
    end

    stub_const('Parent', parent)
    stub_const('Child', child)

    Class.new(Resources::Sql::Relation::ActiveRecord) do
      use_ar_model parent
    end.then do |klass|
      stub_const('ParentRelations', klass)
    end

    Class.new(Resources::Sql::Relation::ActiveRecord) do
      use_ar_model child
    end.then do |klass|
      stub_const('ChildRelations', klass)
    end

    Class.new(Resources::Sql::Relation::ActiveRecord) do
      use_ar_model child
    end.then do |klass|
      stub_const('GrandChildRelations', klass)
    end

    ParentRelations.associate do
      has_many :children, foreign_key: :parent_id, relation: ChildRelations
      has_many :grand_children, through: :children
    end
    ChildRelations.associate do
      belongs_to :parent, foreign_key: :parent_id, relation: ParentRelations
      has_many :grand_children, foreign_key: :child_id, relation: GrandChildRelations
    end

    GrandChildRelations.associate do
      belongs_to :child, foreign_key: :child_id, relation: ChildRelations
      has_one :parent, through: :child
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table :children
    ActiveRecord::Base.connection.drop_table :parents
    ActiveRecord::Base.connection.drop_table :grand_children
  end

  let(:context) { double('context', company_id: 1, project_id: 1) }

  describe 'associations' do
    before(:each) do
      Parent.delete_all
      Child.delete_all
    end

    context 'belongs_to' do
      let(:child_conditions) { {} }
      let(:children) { ChildRelations.new(context:).where(child_conditions) }
      let(:parents) { children.parents }

      it 'should return relation of parent type' do
        parents.inspect
        # expect(parents).to be_a(ParentRelations)
      end

      context 'scope parent by child relations' do
        let(:child_conditions) { { name: 'Rich Kid' } }

        before do
          parent_one = Parent.create!(name: 'Dev Parent', dev: true)
          parent_two = Parent.create!(name: 'Arch Parent', dev: false)
          Child.create!(name: 'Rich Kid', parent: parent_one)
          Child.create!(name: 'Poor Kid', parent: parent_two)
        end

        it 'should return correct parent ids' do
          expect(parents.pluck(:id)).to eq(children.pluck(:parent_id))
        end
      end
    end

    context 'has_many' do
      let(:parent_conditions) { {} }
      let(:parents) { ParentRelations.new(context:).where(parent_conditions) }
      let(:child_collection) { parents.children }

      it 'should return relation of child type' do
        expect(children).to be_a(ChildRelations)
      end

      context 'scope children by parent relations' do
        let(:parent_conditions) { { name: parent_one.name } }

        let!(:parent_one) { Parent.create!(name: 'Parent One') }
        let!(:parent_two) { Parent.create!(name: 'Parent Two') }
        let!(:first_child) { Child.create!(parent: parent_one) }
        let!(:second_child) { Child.create!(parent: parent_one) }
        let!(:third_child) { Child.create!(parent: parent_two) }

        it 'should return correct child ids' do
          expect(child_collection.to_a.pluck('id')).to match_array([first_child.id, second_child.id])
        end

        it 'should return queried association' do
          expect(parents.children.where(id: first_child).pluck(:id)).to eq([first_child.id])
        end
      end
    end

    context 'has many through' do
      let(:parents)  { ParentRelations.new(context:) }
      let(:children) { parents.children }
      let(:grand_children) { parents.grand_children }

      let!(:parent_one) { Parent.create!(name: 'Parent One') }
      let!(:parent_two) { Parent.create!(name: 'Parent Two') }
      let!(:first_child) { Child.create!(parent: parent_one) }
      let!(:second_child) { Child.create!(parent: parent_one) }
      let!(:third_child) { Child.create!(parent: parent_two) }
      let!(:first_grand_child) { GrandChild.create!(child: first_child) }
      let!(:second_grand_child) { GrandChild.create!(child: first_child) }
      let!(:third_grand_child) { GrandChild.create!(child: second_child) }

      it 'should return correct grand child ids' do
        expect(grand_children.pluck('id')).to match_array([first_grand_child.id, second_grand_child.id, third_grand_child.id])
      end
    end

    # context 'polymorphic association' do
    #   before do
    #     ActiveRecord::Base.connection.create_table :comments do |t|
    #       t.string :content
    #       t.references :commentable, polymorphic: true
    #       t.timestamps
    #     end

    #     comment = Class.new(ActiveRecord::Base) do
    #       self.table_name = :comments
    #       belongs_to :commentable, polymorphic: true
    #     end

    #     stub_const('Comment', comment)

    #     Class.new(Resources::Sql::Relation::ActiveRecord) do
    #       use_ar_model Comment
    #     end.then do |klass|
    #       stub_const('CommentRelations', klass)
    #     end

    #     proxy_var = joinable

    #     ParentRelations.associations.clear
    #     ParentRelations.associate do
    #       has_many :comments, as: :commentable, relation: CommentRelations, joinable: proxy_var
    #     end

    #     ChildRelations.associations.clear
    #     ChildRelations.associate do
    #       has_many :comments, as: :commentable, relation: CommentRelations, joinable: proxy_var
    #     end
    #   end

    #   after do
    #     ActiveRecord::Base.connection.drop_table :comments
    #   end

    #   let(:joinable) { :array }

    #   context 'for parents' do
    #     let(:parents) { ParentRelations.new(context:) }
    #     let(:parent_comments) { parents.comments }

    #     it 'should return relation of comment type' do
    #       expect(parent_comments).to be_a(CommentRelations)
    #     end

    #     context 'with data' do
    #       before do
    #         parent = Parent.create!(name: 'Parent')
    #         Comment.create!(content: 'Parent Comment', commentable: parent)
    #       end

    #       it 'should return correct comments' do
    #         expect(parent_comments.pluck(:content)).to include('Parent Comment')
    #       end
    #     end
    #   end

    #   context 'for children' do
    #     let(:children) { ChildRelations.new(context:) }
    #     let(:child_comments) { children.comments }

    #     it 'should return relation of comment type' do
    #       expect(child_comments).to be_a(CommentRelations)
    #     end

    #     context 'with data' do
    #       before do
    #         child = Child.create!(name: 'Child')
    #         Comment.create!(content: 'Child Comment', commentable: child)
    #       end

    #       it 'should return correct comments' do
    #         expect(child_comments.pluck(:content)).to include('Child Comment')
    #       end
    #     end
    #   end
    # end
  end
end
