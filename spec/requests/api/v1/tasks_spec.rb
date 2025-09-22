require 'swagger_helper'

RSpec.describe "API::V1::Tasks", type: :request, swagger_doc: 'v1/swagger.yaml' do
  let(:user) { create(:user, password: 'password123') }
  let(:other_user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:Authorization) { auth_headers_for_user(user)['Authorization'] }

  describe 'GET /api/v1/tasks' do
    path '/api/v1/tasks' do
      get 'retrieve tasks' do
        tags 'Tasks'
        produces 'application/json'
        security [bearerAuth: []]
        parameter name: 'page', in: :query, type: :integer, required: true, description: 'Page number'
        parameter name: 'per_page', in: :query, type: :integer, required: false, description: 'Per page'
        parameter name: 'project_id', in: :query, type: :integer, required: false, description: 'Project id of the tasks'
        parameter name: 'status', in: :query, type: :string, required: false, description: 'Task status filter'
        parameter name: 'due_type', in: :query, type: :string, required: false, description: 'Due type filter'

        response "200", 'tasks in descending order when project id is not given' do
          let(:page) { 1 }
          let(:per_page) { 5 }
          before { create_list(:task, 10, user: user) }

          run_test! do |response|
            res = JSON.parse(response.body)
            expect(res['tasks'].length).to eq(5)
            expect(res['meta']['total']).to eq(10)
            expect(res['meta']['page']).to eq(1)
          end
        end

        response "200", 'filters tasks by project_id when provided' do
          let(:page) { 1 }
          let(:per_page) { 10 }
          let(:project_id) { project.id }
          before do
            create_list(:task, 3, user: user, project: project)
            create_list(:task, 2, user: user) # Different project
          end

          run_test! do |response|
            res = JSON.parse(response.body)
            expect(res['tasks'].length).to eq(3)
            expect(res['meta']['total']).to eq(3)
            res['tasks'].each do |task|
              expect(task['project_id']).to eq(project.id)
            end
          end
        end

        response "200", 'filters tasks by status when provided' do
          let(:page) { 1 }
          let(:per_page) { 10 }
          let(:status) { 'completed' }
          before do
            create_list(:task, 2, user: user, status: :completed)
            create_list(:task, 3, user: user, status: :pending)
          end

          run_test! do |response|
            res = JSON.parse(response.body)
            expect(res['tasks'].length).to eq(2)
            expect(res['meta']['total']).to eq(2)
            res['tasks'].each do |task|
              expect(task['status']).to eq('completed')
            end
          end
        end

        response "200", 'filters overdue tasks when due_type is overdue' do
          let(:page) { 1 }
          let(:per_page) { 10 }
          let(:due_type) { 'overdue' }
          before do
            create(:task, user: user, due_date: 2.days.ago, status: :pending)
            create(:task, user: user, due_date: Date.current, status: :pending)
            create(:task, user: user, due_date: 1.week.from_now, status: :pending)
          end

          run_test! do |response|
            res = JSON.parse(response.body)
            expect(res['tasks'].length).to eq(1)
            expect(res['meta']['total']).to eq(1)
            expect(res['tasks'].first['due_date']).to include(2.days.ago.to_date.to_s)
          end
        end

        response "400", 'returns error when page parameter is missing' do
          let(:page) { nil }

          run_test! do |response|
            expect(response.status).to eq(400)
            res = JSON.parse(response.body)
            expect(res['error']).to eq('page parameter must be positive integer')
          end
        end

        response "400", 'returns error when page parameter is negative' do
          let(:page) { -1 }

          run_test! do |response|
            expect(response.status).to eq(400)
            res = JSON.parse(response.body)
            expect(res['error']).to eq('page parameter must be positive integer')
          end
        end

        response "401", 'returns unauthorized when no auth token provided' do
          let(:page) { 1 }
          let(:Authorization) { nil }

          run_test! do |response|
            expect(response.status).to eq(401)
          end
        end
      end
    end
  end

  describe 'POST /api/v1/tasks' do
    path '/api/v1/tasks' do
      post 'create task' do
        tags 'Tasks'
        produces 'application/json'
        consumes 'application/json'
        security [bearerAuth: []]
        parameter name: :task, in: :body, schema: {
          type: :object,
          properties: {
            task: {
              type: :object,
              properties: {
                title: { type: :string },
                description: { type: :string },
                status: { type: :string },
                priority: { type: :string },
                estimated_minutes: { type: :integer },
                due_date: { type: :string, format: :date },
                project_id: { type: :integer }
              }
            }
          }
        }

        response "201", 'creates task successfully' do
          let(:task) do
            {
              task: {
                title: 'Test Task',
                description: 'Test Description',
                status: 'pending',
                priority: 'medium',
                estimated_minutes: 30,
                due_date: 1.week.from_now.to_date.to_s,
                project_id: project.id
              }
            }
          end

          run_test! do |response|
            expect(response.status).to eq(201)
            res = JSON.parse(response.body)
            expect(res['title']).to eq('Test Task')
            expect(res['description']).to eq('Test Description')
            expect(res['status']).to eq('pending')
            expect(res['priority']).to eq('medium')
            expect(res['estimated_minutes']).to eq(30)
            expect(res['project_id']).to eq(project.id)
          end
        end

        response "422", 'returns validation errors for invalid data' do
          let(:task) do
            {
              task: {
                title: '',
                status: 'pending', # Use valid status
                priority: 'medium', # Use valid priority
                due_date: nil
              }
            }
          end

          run_test! do |response|
            expect(response.status).to eq(422)
            res = JSON.parse(response.body)
            expect(res['errors']).to be_present
            expect(res['errors']).to include("Title can't be blank")
            expect(res['errors']).to include("Due date can't be blank")
          end
        end
      end
    end
  end

  describe 'GET /api/v1/tasks/:id' do
    path '/api/v1/tasks/{id}' do
      get 'retrieve single task' do
        tags 'Tasks'
        produces 'application/json'
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true

        response "200", 'returns task when it exists and belongs to user' do
          let(:task) { create(:task, user: user) }
          let(:id) { task.id }

          run_test! do |response|
            expect(response.status).to eq(200)
            res = JSON.parse(response.body)
            expect(res['id']).to eq(task.id)
            expect(res['title']).to eq(task.title)
            expect(res['user_id']).to eq(user.id)
          end
        end

        response "404", 'returns not found when task does not exist' do
          let(:id) { 99999 }

          run_test! do |response|
            expect(response.status).to eq(404)
            res = JSON.parse(response.body)
            expect(res['error']).to eq('Task not found')
          end
        end

        response "404", 'returns not found when task belongs to another user' do
          let(:other_task) { create(:task, user: other_user) }
          let(:id) { other_task.id }

          run_test! do |response|
            expect(response.status).to eq(404)
            res = JSON.parse(response.body)
            expect(res['error']).to eq('Task not found')
          end
        end
      end
    end
  end

  describe 'PUT /api/v1/tasks/:id' do
    path '/api/v1/tasks/{id}' do
      put 'update task' do
        tags 'Tasks'
        produces 'application/json'
        consumes 'application/json'
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true
        parameter name: :task, in: :body, schema: {
          type: :object,
          properties: {
            task: {
              type: :object,
              properties: {
                title: { type: :string },
                description: { type: :string },
                status: { type: :string },
                priority: { type: :string },
                estimated_minutes: { type: :integer },
                due_date: { type: :string, format: :date },
                project_id: { type: :integer }
              }
            }
          }
        }

        response "200", 'updates task successfully' do
          let(:task_record) { create(:task, user: user, title: 'Original Title') }
          let(:id) { task_record.id }
          let(:task) do
            {
              task: {
                title: 'Updated Title',
                status: 'in_progress',
                priority: 'high'
              }
            }
          end

          run_test! do |response|
            expect(response.status).to eq(200)
            res = JSON.parse(response.body)
            expect(res['title']).to eq('Updated Title')
            expect(res['status']).to eq('in_progress')
            expect(res['priority']).to eq('high')
          end
        end

        response "422", 'returns validation errors for invalid update' do
          let(:task_record) { create(:task, user: user) }
          let(:id) { task_record.id }
          let(:task) do
            {
              task: {
                title: '',
                status: 'pending' # Use valid status
              }
            }
          end

          run_test! do |response|
            expect(response.status).to eq(422)
            res = JSON.parse(response.body)
            expect(res['errors']).to be_present
            expect(res['errors']).to include("Title can't be blank")
          end
        end
      end
    end
  end

  describe 'DELETE /api/v1/tasks/:id' do
    path '/api/v1/tasks/{id}' do
      delete 'delete task' do
        tags 'Tasks'
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true

        response "204", 'deletes task successfully' do
          let(:task) { create(:task, user: user) }
          let(:id) { task.id }

          run_test! do |response|
            expect(response.status).to eq(204)
            expect(Task.find_by(id: task.id)).to be_nil
          end
        end

        response "404", 'returns not found when task does not exist' do
          let(:id) { 99999 }

          run_test! do |response|
            expect(response.status).to eq(404)
            res = JSON.parse(response.body)
            expect(res['error']).to eq('Task not found')
          end
        end

        response "404", 'returns not found when task belongs to another user' do
          let(:other_task) { create(:task, user: other_user) }
          let(:id) { other_task.id }

          run_test! do |response|
            expect(response.status).to eq(404)
            res = JSON.parse(response.body)
            expect(res['error']).to eq('Task not found')
          end
        end
      end
    end
  end
end