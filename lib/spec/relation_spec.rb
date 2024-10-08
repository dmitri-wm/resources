# frozen_string_literal: true

require_relative './spec_helper'

RSpec.describe Resources::Relation, type: :integration do
  before(:all) do
    ActiveRecord::Schema.define do
      create_table :companies do |t|
        t.string :name
      end

      create_table :departments do |t|
        t.string :name
        t.integer :company_id
      end

      create_table :employees do |t|
        t.string :name
        t.integer :department_id
        t.integer :company_id
      end

      create_table :projects do |t|
        t.string :name
        t.integer :department_id
        t.integer :company_id
      end

      create_table :tasks do |t|
        t.string :name
        t.integer :project_id
        t.integer :employee_id
        t.integer :company_id
      end

      create_table :project_assignments do |t|
        t.integer :project_id
        t.integer :employee_id
        t.integer :company_id
      end
    end

    class CompanyModel < ActiveRecord::Base
      self.table_name = 'companies'
    end

    class DepartmentModel < ActiveRecord::Base
      self.table_name = 'departments'
    end

    class EmployeeModel < ActiveRecord::Base
      self.table_name = 'employees'
    end

    class ProjectModel < ActiveRecord::Base
      self.table_name = 'projects'
    end

    class TaskModel < ActiveRecord::Base
      self.table_name = 'tasks'
    end

    class ProjectAssignmentModel < ActiveRecord::Base
      self.table_name = 'project_assignments'
    end

    module Relations
      ASSOCIATIONS = {
        Company: proc do |klass|
          klass.associate do
            has_many :departments
            has_many :employees, through: :departments
            has_many :projects, through: :departments
          end
        end,
        Employee: proc do |klass|
          klass.associate do
            belongs_to :department
            has_many :tasks
            has_one :company, through: :department
            has_many :projects, through: :department
          end
        end,
        Project: proc do |klass|
          klass.associate do
            belongs_to :department
            has_many :tasks
            has_many :project_assignments
            has_many :employees, through: :project_assignments, assoc_name: :employee
            belongs_to :company, through: :department
          end
        end,
        Task: proc do |klass|
          klass.associate do
            belongs_to :project
            belongs_to :employee
            has_one :department, through: :project
            has_one :company, through: :department
          end
        end,
        ProjectAssignment: proc do |klass|
          klass.associate do
            belongs_to :project
            belongs_to :employee
          end
        end,
        Department: proc do |klass|
          klass.associate do
            belongs_to :company
            has_many :employees
            has_many :projects
            has_many :tasks, through: :employees
          end
        end
      }.freeze
    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table(:companies)
    ActiveRecord::Base.connection.drop_table(:departments)
    ActiveRecord::Base.connection.drop_table(:employees)
    ActiveRecord::Base.connection.drop_table(:projects)
    ActiveRecord::Base.connection.drop_table(:tasks)
    ActiveRecord::Base.connection.drop_table(:project_assignments)
  end

  let_it_be(:company) { CompanyModel.create!(id: 1, name: 'Test Company') }
  let_it_be(:department) { DepartmentModel.create!(name: 'Test Department', company_id: company.id) }
  let_it_be(:department_two) { DepartmentModel.create!(name: 'Test Department Two', company_id: company.id) }
  let_it_be(:employee) { EmployeeModel.create!(name: 'Test Employee', department_id: department.id, company_id: company.id) }
  let_it_be(:employee_two) { EmployeeModel.create!(name: 'Test Employee Two', department_id: department_two.id, company_id: company.id) }
  let_it_be(:project) { ProjectModel.create!(name: 'Test Project', company_id: company.id, department_id: department.id) }
  let_it_be(:project_two) { ProjectModel.create!(name: 'Test Project Two', company_id: company.id, department_id: department.id) }
  let_it_be(:task) { TaskModel.create!(name: 'Test Task', project_id: project.id, employee_id: employee.id, company_id: company.id) }
  let_it_be(:task_two) { TaskModel.create!(name: 'Task Two', project_id: project.id, employee_id: employee_two.id, company_id: company.id) }
  let_it_be(:project_assignment) { ProjectAssignmentModel.create!(project_id: project.id, employee_id: employee.id, company_id: company.id) }
  let_it_be(:project_assignment_two) { ProjectAssignmentModel.create!(project_id: project.id, employee_id: employee_two.id, company_id: company.id) }

  let_it_be(:other_company) { CompanyModel.create!(id: 2, name: 'Other Company') }
  let_it_be(:other_department) { DepartmentModel.create!(name: 'Other Department', company_id: other_company.id) }
  let_it_be(:other_employee) { EmployeeModel.create!(name: 'Other Employee', department_id: other_department.id, company_id: other_company.id) }
  let_it_be(:other_project) { ProjectModel.create!(name: 'Other Project', company_id: other_company.id, department_id: other_department.id) }
  let_it_be(:other_task) { TaskModel.create!(name: 'Other Task', project_id: other_project.id, employee_id: other_employee.id, company_id: other_company.id) }

  let_it_be(:context) { OpenStruct.new(company_id: company.id, project_id: project.id) }

  shared_context 'behaves like relation' do
    describe 'association types' do
      context 'has_many' do
        subject do
          company_relation.where(id: company.id)
                          .departments.map(&:name)
        end

        it 'returns associated records' do
          is_expected.to eq(['Test Department', 'Test Department Two'])
        end
      end

      context 'belongs_to' do
        subject do
          department_relation.where(id: department.id).companies.map(&:name)
        end

        it 'returns the associated record' do
          is_expected.to eq(['Test Company'])
        end
      end

      context 'has_many :through' do
        subject do
          company_relation.where(id: company.id)
                          .employees.map(&:name)
        end

        it 'returns associated records through another association' do
          is_expected.to eq(['Test Employee', 'Test Employee Two'])
        end
      end

      context 'has_one :through' do
        subject do
          employee_relation.where(id: employee.id)
                           .companies.map(&:name)
        end

        it 'returns the associated record through another association' do
          is_expected.to eq(['Test Company'])
        end
      end

      context 'belongs_to :through' do
        subject do
          project_relation.where(id: project.id).companies.map(&:name)
        end

        it 'returns the associated record through another association' do
          is_expected.to eq(['Test Company'])
        end
      end
    end

    describe 'query methods' do
      subject(:relation) { department_relation }

      it 'supports where clauses' do
        result = relation.where(name: 'Test Department').to_a
        expect(result.map(&:name)).to eq(['Test Department'])
      end

      it 'supports order clauses' do
        expect(relation.order(name: :asc).to_a.map(&:name)).to eq(['Test Department', 'Test Department Two'])
        expect(relation.order(name: :desc).to_a.map(&:name)).to eq(['Test Department Two', 'Test Department'])
      end

      it 'supports pagination' do
        expect(relation.paginate(page: 1, per_page: 1).to_a.map(&:name)).to eq(['Test Department'])
        expect(relation.paginate(page: 2, per_page: 1).to_a.map(&:name)).to eq(['Test Department Two'])
        expect(relation.paginate(page: 1, per_page: 4).to_a.map(&:name)).to eq(['Test Department', 'Test Department Two'])
      end

      describe 'joins' do
        it 'supports left outer join' do
          DepartmentModel.create!(name: 'No Project', company_id: company.id)

          result = department_relation.left_outer_join(:projects).distinct(:id).to_a
          expect(result.map(&:name)).to match_array(['Test Department', 'Test Department Two', 'No Project'])
        end

        it 'supports joining through associations' do
          result = department_relation.joins(:tasks).distinct.to_a
          expect(result.map(&:name)).to eq(['Test Department', 'Test Department Two'])
        end

        it 'supports nested joins' do
          result = company_relation.joins(departments: { employees: :tasks }).distinct.to_a
          expect(result.map(&:name)).to eq(['Test Company'])
        end

        it 'supports joins with conditions' do
          result = company_relation.joins(:departments).where(departments: { name: 'Test Department' }).to_a
          expect(result.map(&:name)).to eq(['Test Company'])
        end

        it 'supports joins across different relation types' do
          result = project_relation.join(relation: employee_relation, join_keys: { id: :department_id }, name: :employees)
                                   .where(employees: { name: 'Test Employee' })
                                   .to_a
          expect(result.map(&:name)).to eq(['Test Project'])
        end

        it 'supports complex multi-table joins' do
          result = company_relation.joins(departments: { projects: :tasks })
                                   .where(tasks: { name: 'Test Task' })
                                   .to_a
          expect(result.map(&:name)).to eq(['Test Company'])
        end

        it 'supports joining has_many :through associations' do
          result = company_relation.employees.to_a
          expect(result.map(&:name)).to eq(['Test Employee', 'Test Employee Two'])
        end

        it 'supports joining belongs_to :through associations' do
          result = task_relation.companies.to_a
          expect(result.map(&:name)).to eq(['Test Company'])
        end

        it 'supports joining has_one :through associations' do
          result = employee_relation.companies.to_a
          expect(result.map(&:name)).to eq(['Test Company'])
        end

        it 'supports chaining multiple joins' do
          result = company_relation.joins(:departments)
                                   .joins(:employees)
                                   .joins(:projects)
                                   .distinct
                                   .to_a
          expect(result.map(&:name)).to eq(['Test Company'])
        end

        it 'supports joining with custom conditions' do
          result = company_relation.joins(:departments)
                                   .where(departments: { name: 'Test Department' })
                                   .joins(:employees)
                                   .where(employees: { name: 'Test Employee' })
                                   .to_a
          expect(result.map(&:name)).to eq(['Test Company'])
        end
      end
    end

    describe 'aggregation methods' do
      subject(:relation) { project_relation }

      it 'supports count' do
        expect(relation.count).to eq(2)
      end

      it 'supports exists?' do
        expect(relation.exists?).to be true
        expect(relation.where(name: 'Non-existent').exists?).to be false
      end
    end
  end

  # [Resources::Sql::Relation::ActiveRecord, Resource::DataService::Relation].each do |_parent_class|
  describe 'ActiveRecord adapter' do
    include_context 'behaves like relation' do
      before_all do
        Resources::Registry::Namespaces::Relations.instance_variable_set(:@store, {})
      end

      let_it_be(:company_relation) do
        class CompanyRelation < ::Resources::Sql::Relation::ActiveRecord
          relation_name :companies
          use_ar_model CompanyModel
        end

        CompanyRelation.tap(&Relations::ASSOCIATIONS[:Company]).new(context: context)
      end

      let_it_be(:department_relation) do
        class DepartmentRelation < ::Resources::Sql::Relation::ActiveRecord
          relation_name :departments
          use_ar_model DepartmentModel
        end

        DepartmentRelation.tap(&Relations::ASSOCIATIONS[:Department]).new(context: context)
      end

      let_it_be(:employee_relation) do
        class EmployeeRelation < ::Resources::Sql::Relation::ActiveRecord
          relation_name :employees
          use_ar_model EmployeeModel
        end

        EmployeeRelation.tap(&Relations::ASSOCIATIONS[:Employee]).new(context: context)
      end

      let_it_be(:project_relation) do
        class ProjectRelation < ::Resources::Sql::Relation::ActiveRecord
          relation_name :projects
          use_ar_model ProjectModel
        end

        ProjectRelation.tap(&Relations::ASSOCIATIONS[:Project]).new(context: context)
      end

      let_it_be(:task_relation) do
        class TaskRelation < ::Resources::Sql::Relation::ActiveRecord
          relation_name :tasks
          use_ar_model TaskModel
        end

        TaskRelation.tap(&Relations::ASSOCIATIONS[:Task]).new(context: context)
      end

      let_it_be(:project_assignment_relation) do
        class ProjectAssignmentRelation < ::Resources::Sql::Relation::ActiveRecord
          relation_name :project_assignments
          use_ar_model ProjectAssignmentModel
        end

        ProjectAssignmentRelation.tap(&Relations::ASSOCIATIONS[:ProjectAssignment]).new(context: context)
      end
    end
  end

  describe 'DataService adapter' do
    include_context 'behaves like relation' do
      before_all do
        Resources::Registry::Namespaces::Relations.instance_variable_set(:@store, {})
      end

      let_it_be(:basic_service) do
        class BasicService
          class << self
            attr_accessor :model

            def [](model_class)
              Class.new(self) do
                self.model = model_class
              end
            end
          end

          attr_accessor :context

          def initialize(context:)
            self.context = context
          end

          def base_scope
            self.class.model
          end

          def find_some(filters: {})
            base_scope.where(filters).then do |scope|
              scope = scope.where(company_id: context.company_id) if base_scope.column_names.include?('company_id')
              scope
            end.to_a.map(&:attributes)
          end
        end
      end

      let_it_be(:base) do
        Class.new(Resources::DataService::Relation) do
          relation_name :base
          supports %i[order filter paginate]

          service_call proc { |datasource, options| datasource.find_some(filters: options[:filters]) }
        end
      end

      let_it_be(:company_relation) do
        Class.new(base) do
          relation_name :companies
          use_data_service BasicService[CompanyModel]
        end.tap(&Relations::ASSOCIATIONS[:Company]).new(context: context)
      end

      let_it_be(:department_relation) do
        Class.new(base) do
          relation_name :departments
          use_data_service BasicService[DepartmentModel]

          service_call proc { |datasource, options| datasource.find_some(filters: options[:filters]) }
        end.tap(&Relations::ASSOCIATIONS[:Department]).new(context: context)
      end

      let_it_be(:employee_relation) do
        Class.new(base) do
          relation_name :employees
          use_data_service BasicService[EmployeeModel]

          service_call proc { |datasource, options| datasource.find_some(filters: options[:filters]) }
        end.tap(&Relations::ASSOCIATIONS[:Employee]).new(context: context)
      end

      let_it_be(:project_relation) do
        Class.new(base) do
          relation_name :projects
          use_data_service BasicService[ProjectModel]

          service_call proc { |datasource, options| datasource.find_some(filters: options[:filters]) }
        end.tap(&Relations::ASSOCIATIONS[:Project]).new(context: context)
      end

      let_it_be(:task_relation) do
        Class.new(base) do
          relation_name :tasks
          use_data_service BasicService[TaskModel]

          service_call proc { |datasource, options| datasource.find_some(filters: options[:filters]) }
        end.tap(&Relations::ASSOCIATIONS[:Task]).new(context: context)
      end

      let_it_be(:project_assignment_relation) do
        Class.new(base) do
          relation_name :project_assignments
          use_data_service BasicService[ProjectAssignmentModel]

          service_call proc { |datasource, options| datasource.find_some(filters: options[:filters]) }
        end.tap(&Relations::ASSOCIATIONS[:ProjectAssignment]).new(context: context)
      end
    end
  end
end
