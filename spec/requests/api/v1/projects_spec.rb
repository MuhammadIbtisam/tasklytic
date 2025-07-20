require 'swagger_helper'

RSpec.describe 'API::V1::Projects', swagger_doc: 'v1/swagger.yaml' do
  let(:user) { create(:user, password: 'password123') }
  let(:Authorization) { auth_headers_for_user(user)['Authorization'] }

  path '/api/v1/projects' do
    get 'retrieve_projects' do
      tags 'Projects'
      produces 'application/json'
      security [bearerAuth: []]
      parameter name: 'page', in: :query, type: :integer, required: true, description: 'Page number'
      parameter name: 'per_page', in: :query, type: :integer, required: false, description: 'Items per page'
      parameter name: 'user_id', in: :query, type: :integer, required: false, description: "Item per page"
      response '200', 'project found' do
        let(:page) { 1 }
        let(:per_page) { 2 }

        before { create_list(:project, 5) }

        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['projects'].length).to eq(2)
          expect(res['meta']).to include('page', 'per_page', 'total', 'total_pages')
        end
      end

      response '200', 'when no project is associated to the user' do
        let(:page) { 1 }
        let(:per_page) { 2 }
        let(:user_id) { user.id + 1 }

        before { create_list(:project, 5, user: user) }

        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['projects'].length).to eq(0)
          expect(res['meta']).to include('page', 'per_page', 'total', 'total_pages')
        end
      end

      response '200', 'when projects is associated to the user' do
        let(:page) { 1 }
        let(:per_page) { 2 }
        let(:user_id) { user.id }

        before { create_list(:project, 5, user: user) }

        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['projects'].length).to eq(2)
          expect(res['meta']).to include('page', 'per_page', 'total', 'total_pages')
        end
      end

      response '200', 'return the projects in descending order by their creation date' do
        let(:page) { 1 }
        let(:per_page) { 3 }

        let!(:oldest_project) { create(:project, created_at: 3.days.ago) }
        let!(:old_project) { create(:project, created_at: 2.days.ago) }
        let!(:new_project) { create(:project) }
        puts 'I am here'
        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['projects'].first['id']).to eq(new_project.id)
          expect(res['projects'].last['id']).to eq(oldest_project.id)
        end
      end

      response '200', 'no project for the user' do
        let(:page) { 1 }
        before { Project.delete_all }


        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['projects']).to eq([])
          expect(res['meta']['total']).to eq(0)
          expect(res['meta']['total_pages']).to eq(0)
        end
      end

      response '200', 'per_page cap' do
        let(:page) { 1 }
        before { create_list(:project, 60, user: user) }

        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['projects'].length).to eq(10)
        end
      end

      response '200', 'per_page cap' do
        let(:page) { 1 }
        let(:per_page) { 100 }
        before { create_list(:project, 60, user: user) }
        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res['projects'].length).to eq(50)
        end
      end

      response '400', 'Missing required parameter: page' do
        let(:page) { nil }
        run_test! do |response|
          expect( JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
        end
      end

      response '400', 'page param must be positive' do
        let(:page) { 0 }
        run_test! do |response|
          expect( JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
        end
      end

      response '400', 'page param must be positive' do
        let(:page) { -1 }
        run_test! do |response|
          expect( JSON.parse(response.body)['error']).to eq('page parameter must be positive integer')
        end
      end
    end

    post 'create_project' do
      tags 'Projects'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string }
            },
            required: ['name']
          }
        }
      }

      response '201', 'project created' do
        let(:project) { { project: { name: 'Test Project', description: 'This is only a test project' } } }
        run_test!
      end

      response '422', 'invalid request' do
        let(:project) { { project: { name: '' } } }
        run_test!
      end
    end
  end

  path '/api/v1/projects/{id}' do
    get 'Retrieves a project' do
      tags 'Projects'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :id, in: :path, type: :integer, required: true

      response '200', 'project found' do
        let(:project) { create(:project, user: user) }
        let(:id) { project.id }
        run_test! do |response|
          res = JSON.parse(response.body)
          expect(res).to include('project', 'tasks', 'user_name')
        end
      end

      response '404', 'project not found' do
        let(:id) { 999 }
        run_test!
      end

      response '400', 'Page parameter is required' do
        let(:id) {}
        run_test!
      end
    end

    put 'Updates a project' do
      tags 'Projects'
      consumes 'application/json'
      produces 'application/json'
      security [bearerAuth: []]

      parameter name: :id, in: :path, type: :integer, required: true
      parameter name: :project, in: :body, schema: {
        type: :object,
        properties: {
          project: {
            type: :object,
            properties: {
              name: { type: :string },
              description: { type: :string }
            }
          }
        }
      }

      response '200', 'project updated' do
        let(:project_record) { create(:project, user: user) }
        let(:id) { project_record.id }
        let(:project) { { project: { name: 'Updated Project' } } }
        run_test!
      end

      response '404', 'project not found' do
        let(:user1) { create(:user) }
        let(:project_record) { create(:project, user: user1) }
        let(:id) { project_record.id }
        let(:project) { { project: { name: 'Updated Project' } } }
        run_test!
      end
    end

    delete 'Deletes a project' do
      tags 'Projects'
      security [bearerAuth: []]

      parameter name: :id, in: :path, type: :integer, required: true

      response '204', 'project deleted' do
        let(:project) { create(:project, user: user) }
        let(:id) { project.id }
        run_test!
      end

      response '404', 'project not found' do
        let(:user1) { create(:user) }
        let(:project) { create(:project, user: user1) }
        let(:id) { project.id }
        run_test!
      end
    end
  end
end