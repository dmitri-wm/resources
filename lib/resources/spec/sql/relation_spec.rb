# frozen_string_literal: true

require_relative '../spec_helper'

RSpec.describe Resources::Sql::Relation::ActiveRecord, type: :integration do
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
      end

      create_table :projects do |t|
        t.string :name
        t.integer :department_id
      end

      create_table :tasks do |t|
        t.string :name
        t.integer :project_id
        t.integer :employee_id
      end

      create_table :project_assignments do |t|
        t.integer :project_id
        t.integer :employee_id
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

    class Department < Resources::Sql::Relation::ActiveRecord
      use_ar_model DepartmentModel

      associate do
        belongs_to :company
        has_many :employees
        has_many :projects
        has_many :tasks, through: :projects
      end
    end

    module Relations
      class Company < Resources::Sql::Relation::ActiveRecord
        use_ar_model CompanyModel

        associate do
          has_many :departments
          has_many :employees, through: :departments
          has_many :projects, through: :departments
        end
      end

      class Employee < Resources::Sql::Relation::ActiveRecord
        use_ar_model EmployeeModel

        associate do
          belongs_to :department
          has_many :tasks
          has_one :company, through: :department
          has_many :projects, through: :department
        end
      end

      class Project < Resources::Sql::Relation::ActiveRecord
        use_ar_model ProjectModel

        associate do
          belongs_to :department
          has_many :tasks
          has_many :project_assignments
          has_many :employees, through: :project_assignments
          belongs_to :company, through: :department
        end
      end

      class Task < Resources::Sql::Relation::ActiveRecord
        use_ar_model TaskModel

        associate do
          belongs_to :project
          belongs_to :employee
          has_one :department, through: :project
          has_one :company, through: :department
        end
      end

      class ExternalData < Resources::DataService::Relation
        use_data_service :external_data
      end
    end
  end

  # after(:all) do
  #   ActiveRecord::Base.connection.drop_table(:companies)
  #   ActiveRecord::Base.connection.drop_table(:departments)
  #   ActiveRecord::Base.connection.drop_table(:employees)
  #   ActiveRecord::Base.connection.drop_table(:projects)
  #   ActiveRecord::Base.connection.drop_table(:tasks)
  #   ActiveRecord::Base.connection.drop_table(:project_assignments)
  # end

  let(:context) { double('context', company_id: company.id, project_id: project) }
  let_it_be(:company) { CompanyModel.create!(name: 'Test Company') }
  let_it_be(:other_company) { CompanyModel.create!(name: 'Other Company') }
  let_it_be(:department) { DepartmentModel.create!(name: 'Test Department', company_id: company.id) }
  let_it_be(:department_two) { DepartmentModel.create!(name: 'Test Department Two', company_id: company.id) }
  let_it_be(:other_department) { DepartmentModel.create!(name: 'Other Department', company_id: other_company.id) }
  let_it_be(:employee) { EmployeeModel.create!(name: 'Test Employee', department_id: department.id) }
  let_it_be(:employee_two) { EmployeeModel.create!(name: 'Test Employee Two', department_id: department_two.id) }
  let_it_be(:other_employee) { EmployeeModel.create!(name: 'Other Employee', department_id: other_department.id) }
  let_it_be(:project) { ProjectModel.create!(name: 'Test Project', department_id: department.id) }
  let_it_be(:other_project) { ProjectModel.create!(name: 'Other Project', department_id: other_department.id) }
  let_it_be(:task) { TaskModel.create!(name: 'Test Task', project_id: project.id, employee_id: employee.id) }
  let_it_be(:task_two) { TaskModel.create!(name: 'Task Two', project_id: project.id, employee_id: employee_two.id) }
  let_it_be(:other_task) { TaskModel.create!(name: 'Other Task', project_id: other_project.id, employee_id: other_employee.id) }
  let_it_be(:project_assignment) { ProjectAssignmentModel.create!(project_id: project.id, employee_id: employee.id) }

  describe 'association types' do
    context 'has_many' do
      subject do
        Relations::Company.new(context: context)
                          .where(id: company.id)
                          .departments.map(&:name)
      end

      it 'returns associated records' do
        is_expected.to eq(['Test Department', 'Test Department Two'])
      end
    end

    context 'belongs_to' do
      subject do
        Department.new(context: context).where(id: department.id).companies.map(&:name)
      end

      it 'returns the associated record' do
        is_expected.to eq(['Test Company'])
      end
    end

    context 'has_many :through' do
      subject do
        Relations::Company.new(context: context)
                          .where(id: company.id)
                          .employees.map(&:name)
      end

      it 'returns associated records through another association' do
        is_expected.to eq(['Test Employee', 'Test Employee Two'])
      end
    end

    context 'has_one :through' do
      subject do
        Relations::Employee.new(context: context)
                           .where(id: employee.id)
                           .companies.map(&:name)
      end

      it 'returns the associated record through another association' do
        is_expected.to eq(['Test Company'])
      end
    end

    context 'belongs_to :through' do
      subject do
        Relations::Project.new(context: context).where(id: project.id).companies.map(&:name)
      end

      it 'returns the associated record through another association' do
        is_expected.to eq(['Test Company'])
      end
    end
  end

  describe 'query methods' do
    subject(:relation) { Relations::Project.new(context: context) }

    it 'supports where clauses' do
      result = relation.where(name: 'Test Project').to_a
      expect(result.map(&:name)).to eq(['Test Project'])
    end

    it 'supports order clauses' do
      expect(relation.order(name: :desc).to_a.map(&:name)).to eq(['Test Project', 'Other Project'])
      expect(relation.order(name: :asc).to_a.map(&:name)).to eq(['Other Project', 'Test Project'])
    end

    it 'supports joins' do
      result = relation.departments.joins(employees: :tasks).where(tasks: { name: 'Test Task' }).to_a.map(&:name)
      expect(result).to eq(['Test Department'])
    end
  end

  describe 'aggregation methods' do
    subject(:relation) { Relations::Project.new(context: context) }

    it 'supports count' do
      expect(relation.count).to eq(2)
    end

    it 'supports exists?' do
      expect(relation.exists?).to be true
      expect(relation.where(name: 'Non-existent').exists?).to be false
    end
  end
end
