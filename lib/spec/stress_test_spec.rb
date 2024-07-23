# spec/relation_stress_spec.rb

require 'spec_helper'

RSpec.describe 'Relation Stress Tests', type: :integration do
  # Setup test data
  before(:all) do
    # SQL setup
    ActiveRecord::Schema.define do
      create_table :users do |t|
        t.string :name
        t.string :email
      end

      create_table :posts do |t|
        t.string :title
        t.text :content
        t.integer :user_id
      end

      create_table :comments do |t|
        t.text :content
        t.integer :post_id
        t.integer :user_id
      end
    end

    class UserModel < ActiveRecord::Base
      self.table_name = 'users'
    end

    class PostModel < ActiveRecord::Base
      self.table_name = 'posts'
    end

    class CommentModel < ActiveRecord::Base
      self.table_name = 'comments'
    end

    # Create some sample data
    10.times do |i|
      user = UserModel.create!(name: "User #{i}", email: "user#{i}@example.com")
      3.times do |j|
        post = PostModel.create!(title: "Post #{j} by User #{i}", content: "Content #{j}", user_id: user.id)
        2.times do |k|
          CommentModel.create!(content: "Comment #{k} on Post #{j}", post_id: post.id, user_id: user.id)
        end
      end
    end
  end

  # Define relations
  class User < Resources::Sql::Relation::ActiveRecord
    use_ar_model UserModel

    associate do
      has_many :posts
      has_many :comments
      has_many :commented_posts, through: :comments, relation: :posts
    end
  end

  class Post < Resources::Sql::Relation::ActiveRecord
    use_ar_model PostModel

    associate do
      belongs_to :user
      has_many :comments
      has_many :commenters, through: :comments, relation: :users
    end
  end

  class Comment < Resources::Sql::Relation::ActiveRecord
    use_ar_model CommentModel

    associate do
      belongs_to :user
      belongs_to :post
    end
  end

  # Mock DataService
  class ExternalProfileService
    def initialize(context:)
      @context = context
    end

    def to_a
      UserModel.all.map do |user|
        { user_id: user.id, profile_data: "Profile data for #{user.name}" }
      end
    end
  end

  class ExternalProfile < Resources::DataService::Relation
    use_data_service ExternalProfileService

    associate do
      belongs_to :user
    end
  end

  class User
    associate do
      has_one :external_profile
    end
  end

  let(:context) { double('context') }

  describe 'Complex queries and joins' do
    it 'performs a deep join across multiple relations' do
      result = User.new(context: context)
                   .join(relation: Post.new(context: context), join_keys: { id: :user_id })
                   .join(relation: Comment.new(context: context), join_keys: { 'posts.id': :post_id })
                   .join(relation: ExternalProfile.new(context: context), join_keys: { id: :user_id })
                   .where(posts: { title: /Post 1/ })
                   .where(comments: { content: /Comment 0/ })
                   .where(external_profiles: { profile_data: /Profile data/ })
                   .to_a

      expect(result.length).to be > 0
      expect(result.first.keys).to include(:id, :name, :email, :title, :content, :profile_data)
    end

    it 'uses associations to navigate between SQL and DataService relations' do
      result = User.new(context: context)
                   .posts
                   .comments
                   .join(relation: ExternalProfile.new(context: context), join_keys: { user_id: :user_id })
                   .where(external_profiles: { profile_data: /Profile data/ })
                   .to_a

      expect(result.length).to be > 0
      expect(result.first.keys).to include(:id, :content, :post_id, :user_id, :profile_data)
    end
  end

  describe 'Aggregations and calculations' do
    it 'performs aggregations on joined data from different adapters' do
      count = User.new(context: context)
                  .join(relation: ExternalProfile.new(context: context), join_keys: { id: :user_id })
                  .where(external_profiles: { profile_data: /Profile data/ })
                  .count

      expect(count).to eq(10)
    end

    it 'calculates averages using data from both SQL and DataService relations' do
      avg_posts = User.new(context: context)
                      .join(relation: Post.new(context: context), join_keys: { id: :user_id })
                      .join(relation: ExternalProfile.new(context: context), join_keys: { id: :user_id })
                      .group('users.id')
                      .average('COUNT(posts.id)')

      expect(avg_posts.values.first).to eq(3)
    end
  end

  describe 'Complex filtering and sorting' do
    it 'applies complex filters across multiple relations' do
      result = User.new(context: context)
                   .join(relation: Post.new(context: context), join_keys: { id: :user_id })
                   .join(relation: Comment.new(context: context), join_keys: { 'posts.id': :post_id })
                   .join(relation: ExternalProfile.new(context: context), join_keys: { id: :user_id })
                   .where(name: /User [0-5]/)
                   .where(posts: { title: /Post [0-1]/ })
                   .where(comments: { content: /Comment 1/ })
                   .where(external_profiles: { profile_data: /Profile data for User [3-7]/ })
                   .to_a

      expect(result.length).to be > 0
      expect(result.length).to be < 10
    end

    it 'sorts data from multiple relations' do
      result = User.new(context: context)
                   .join(relation: Post.new(context: context), join_keys: { id: :user_id })
                   .join(relation: ExternalProfile.new(context: context), join_keys: { id: :user_id })
                   .order(name: :desc, 'posts.title': :asc, 'external_profiles.profile_data': :desc)
                   .to_a

      expect(result.length).to eq(30)
      expect(result.first[:name]).to eq('User 9')
      expect(result.last[:name]).to eq('User 0')
    end
  end

  describe 'Nested associations and eager loading' do
    it 'handles nested associations across different adapters' do
      result = User.new(context: context)
                   .posts
                   .comments
                   .commenters
                   .external_profiles
                   .to_a

      expect(result.length).to be > 0
      expect(result.first.keys).to include(:id, :name, :email, :profile_data)
    end

    it 'eager loads associations from both SQL and DataService relations' do
      result = User.new(context: context)
                   .eager_load(:posts, :comments, :external_profile)
                   .to_a

      expect(result.length).to eq(10)
      expect(result.first.association(:posts)).to be_loaded
      expect(result.first.association(:comments)).to be_loaded
      expect(result.first.association(:external_profile)).to be_loaded
    end
  end

  describe 'Performance tests' do
    it 'handles a large number of joins efficiently' do
      start_time = Time.now
      result = User.new(context: context)
                   .join(relation: Post.new(context: context), join_keys: { id: :user_id })
                   .join(relation: Comment.new(context: context), join_keys: { 'posts.id': :post_id })
                   .join(relation: ExternalProfile.new(context: context), join_keys: { id: :user_id })
                   .where(posts: { title: /Post/ })
                   .where(comments: { content: /Comment/ })
                   .where(external_profiles: { profile_data: /Profile data/ })
                   .limit(1000)
                   .to_a
      end_time = Time.now

      expect(result.length).to be > 0
      expect(end_time - start_time).to be < 5.seconds
    end

    it 'efficiently processes a large dataset with complex conditions' do
      start_time = Time.now
      result = User.new(context: context)
                   .join(relation: Post.new(context: context), join_keys: { id: :user_id })
                   .join(relation: Comment.new(context: context), join_keys: { 'posts.id': :post_id })
                   .join(relation: ExternalProfile.new(context: context), join_keys: { id: :user_id })
                   .where(name: /User [0-5]/)
                   .where(posts: { title: /Post [0-2]/ })
                   .where(comments: { content: /Comment [0-1]/ })
                   .where(external_profiles: { profile_data: /Profile data for User [3-7]/ })
                   .order(name: :desc, 'posts.title': :asc, 'comments.content': :desc)
                   .limit(10_000)
                   .to_a
      end_time = Time.now

      expect(result.length).to be > 0
      expect(end_time - start_time).to be < 10.seconds
    end
  end
end
