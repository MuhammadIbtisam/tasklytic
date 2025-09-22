require 'swagger_helper'

RSpec.describe 'API::V1::Tasks', type: :request, swagger_doc: 'v1/swagger.yaml' do
  let(:user) { create(:user, password: 'password123') }
  let(:other_user) { create(:user) }
  let(:project) { create(:project, user: user) }
  let(:other_project) { create(:project, user: other_user) }
  let(:Authorization) { auth_headers_for_user(user)['Authorization'] }

  describe 'GET /api/v1/tasks' do
    path '/api/v1/tasks' do
      get 'retrieve_tasks' do
        tags 'Tasks'
        produces 'application/json'
        security [bearerAuth: []]
        parameter name: 'page', in: :query, type: :integer, required: true, description: 'Page Number'
        parameter name: 'per_page', in: :query, type: :integer, required: false, description: 'Per Page'
        parameter name: 'status', in: :query, type: :string, required: false, description: 'Task status filter'
        parameter name: 'project_id', in: :query, type: :integer, required: false, description: 'Project ID filter'
        parameter name: 'due_type', in: :query, type: :string, required: false, description: 'Due type filter: overdue, due_today, due_this_week'

        context 'when page parameter is missing or invalid' do
          response '400', 'Missing required Parameter: page' do
            let(:page) { nil }
            run_test! do |response|
              expect(JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
            end
          end

          response '400', 'page parameter must be positive' do
            let(:page) { -1 }
            run_test! do |response|
              expect(JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
            end
          end

          response '400', 'page parameter is zero' do
            let(:page) { 0 }
            run_test! do |response|
              expect(JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
            end
          end

          response '400', 'page parameter is not a number' do
            let(:page) { 'invalid' }
            run_test! do |response|
              expect(JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
            end
          end
        end

        context 'when tasks are found' do
          response '200', 'returns paginated tasks' do
            let(:page) { 1 }
            let(:per_page) { 2 }
            before { create_list(:task, 5, user: user, project: project) }

            run_test! do |response|
              expect(response.status).to eq(200)
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(2)
              expect(res['meta']['total']).to eq(5)
              expect(res['meta']['total_pages']).to eq(3)
              expect(res['meta']['page']).to eq(1)
              expect(res['meta']['per_page']).to eq(2)
            end
          end

          response '200', 'returns tasks in descending order by created_at' do
            let(:page) { 1 }
            let(:per_page) { 10 }
            before do
              create(:task, user: user, title: 'First Task', created_at: 2.days.ago)
              create(:task, user: user, title: 'Second Task', created_at: 1.day.ago)
              create(:task, user: user, title: 'Third Task', created_at: Time.current)
            end

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].first['title']).to eq('Third Task')
              expect(res['tasks'].last['title']).to eq('First Task')
            end
          end
        end

        context 'when no tasks are found' do
          response '200', 'returns empty result when no tasks for user' do
            let(:page) { 1 }
            let(:per_page) { 2 }
            before { create_list(:task, 5, user: other_user) }

            run_test! do |response|
              expect(response.status).to eq(200)
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(0)
              expect(res['meta']['total']).to eq(0)
              expect(res['meta']['total_pages']).to eq(0)
            end
          end

          response '200', 'returns empty result when no tasks exist' do
            let(:page) { 1 }
            let(:per_page) { 2 }
            before { Task.delete_all }

            run_test! do |response|
              expect(response.status).to eq(200)
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(0)
              expect(res['meta']['total']).to eq(0)
              expect(res['meta']['total_pages']).to eq(0)
            end
          end
        end

        context 'when per_page parameter is provided' do
          response '200', 'respects per_page parameter' do
            let(:page) { 1 }
            let(:per_page) { 3 }
            before { create_list(:task, 10, user: user) }

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(3)
              expect(res['meta']['per_page']).to eq(3)
            end
          end

          response '200', 'caps per_page at maximum of 50' do
            let(:page) { 1 }
            let(:per_page) { 100 }
            before { create_list(:task, 30, user: user) }

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(30)
              expect(res['meta']['per_page']).to eq(50) # Should be capped at 50
            end
          end

          response '200', 'uses default per_page when not provided' do
            let(:page) { 1 }
            before { create_list(:task, 15, user: user) }

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(10) # Default per_page
              expect(res['meta']['per_page']).to eq(10)
            end
          end
        end

        context 'when status filter is provided' do
          response '200', 'filters tasks by status' do
            let(:page) { 1 }
            let(:per_page) { 10 }
            let(:status) { 'pending' }
            before do
              create(:task, user: user, status: :pending)
              create(:task, user: user, status: :in_progress)
              create(:task, user: user, status: :completed)
            end

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(1)
              expect(res['tasks'].first['status']).to eq('pending')
            end
          end
        end

        context 'when project_id filter is provided' do
          response '200', 'filters tasks by project_id' do
            let(:page) { 1 }
            let(:per_page) { 10 }
            let(:project_id) { project.id }
            before do
              create(:task, user: user, project: project)
              create(:task, user: user, project: other_project)
            end

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(1)
              expect(res['tasks'].first['project_id']).to eq(project.id)
            end
          end
        end

        context 'when due_type filter is provided' do
          response '200', 'filters overdue tasks' do
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
            end
          end

          response '200', 'filters tasks due today' do
            let(:page) { 1 }
            let(:per_page) { 10 }
            let(:due_type) { 'due_today' }
            before do
              create(:task, user: user, due_date: 2.days.ago, status: :pending)
              create(:task, user: user, due_date: Date.current, status: :pending)
              create(:task, user: user, due_date: 1.day.from_now, status: :pending)
            end

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(1)
            end
          end

          response '200', 'filters tasks due this week' do
            let(:page) { 1 }
            let(:per_page) { 10 }
            let(:due_type) { 'due_this_week' }
            before do
              create(:task, user: user, due_date: 2.days.ago, status: :pending)
              create(:task, user: user, due_date: 1.day.from_now, status: :pending)
              create(:task, user: user, due_date: 2.weeks.from_now, status: :pending)
            end

            run_test! do |response|
              res = JSON.parse(response.body)
              expect(res['tasks'].length).to eq(1)
            end
          end
        end
      end
    end
  end

  describe 'POST /api/v1/tasks' do
    path '/api/v1/tasks' do
      post 'create_task' do
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
              },
              required: ['title', 'status', 'priority', 'due_date']
            }
          }
        }

        context 'with valid parameters' do
          response '201', 'creates a new task' do
            let(:task) do
              {
                task: {
                  title: 'New Task',
                  description: 'Task description',
                  status: 'pending',
                  priority: 'medium',
                  estimated_minutes: 60,
                  due_date: 1.week.from_now.to_date.to_s,
                  project_id: project.id
                }
              }
            end

            run_test! do |response|
              expect(response.status).to eq(201)
              res = JSON.parse(response.body)
              expect(res['title']).to eq('New Task')
              expect(res['description']).to eq('Task description')
              expect(res['status']).to eq('pending')
              expect(res['priority']).to eq('medium')
              expect(res['estimated_minutes']).to eq(60)
              expect(res['project_id']).to eq(project.id)
            end
          end
        end

        context 'with invalid parameters' do
          response '422', 'returns validation errors' do
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
              expect(res['errors']).to include("Title can't be blank")
              expect(res['errors']).to include("Due date can't be blank")
            end
          end
        end
      end
    end
  end

  describe 'GET /api/v1/tasks/:id' do
    path '/api/v1/tasks/{id}' do
      get 'retrieve_task' do
        tags 'Tasks'
        produces 'application/json'
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true

        context 'when task exists and belongs to user' do
          response '200', 'returns the task' do
            let(:task) { create(:task, user: user) }
            let(:id) { task.id }

            run_test! do |response|
              expect(response.status).to eq(200)
              res = JSON.parse(response.body)
              expect(res['id']).to eq(task.id)
              expect(res['title']).to eq(task.title)
            end
          end
        end

        context 'when task does not exist' do
          response '404', 'returns not found error' do
            let(:id) { 99999 }

            run_test! do |response|
              expect(response.status).to eq(404)
              res = JSON.parse(response.body)
              expect(res['error']).to eq('Task not found')
            end
          end
        end

        context 'when task belongs to another user' do
          response '404', 'returns not found error' do
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

  describe 'PUT /api/v1/tasks/:id' do
    path '/api/v1/tasks/{id}' do
      put 'update_task' do
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

        context 'with valid parameters' do
          response '200', 'updates the task' do
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
        end

        context 'with invalid parameters' do
          response '422', 'returns validation errors' do
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
              expect(res['errors']).to include("Title can't be blank")
            end
          end
        end

        context 'when task does not exist' do
          response '404', 'returns not found error' do
            let(:id) { 99999 }
            let(:task) { { task: { title: 'New Title' } } }

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

  describe 'DELETE /api/v1/tasks/:id' do
    path '/api/v1/tasks/{id}' do
      delete 'delete_task' do
        tags 'Tasks'
        security [bearerAuth: []]
        parameter name: :id, in: :path, type: :integer, required: true

        context 'when task exists and belongs to user' do
          response '204', 'deletes the task' do
            let(:task) { create(:task, user: user) }
            let(:id) { task.id }

            run_test! do |response|
              expect(response.status).to eq(204)
              expect(Task.find_by(id: task.id)).to be_nil
            end
          end
        end

        context 'when task does not exist' do
          response '404', 'returns not found error' do
            let(:id) { 99999 }

            run_test! do |response|
              expect(response.status).to eq(404)
              res = JSON.parse(response.body)
              expect(res['error']).to eq('Task not found')
            end
          end
        end

        context 'when task belongs to another user' do
          response '404', 'returns not found error' do
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
end