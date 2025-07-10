require 'swagger_helper'

RSpec.describe 'API::V1::Projects', swagger_doc: 'v1/swagger.yaml' do
  let(:user) { create(:user) }
  let(:Authorization) { "Bearer #{user.generate_jwt}" }
  
  path '/api/v1/projects' do
    get 'retrieve_projects' do
      tags 'Projects'
      produces 'application/json'
      security [bearerAuth: []]

      response '200', 'project found' do
        header 'Authorization', :Authorization
        run_test!
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
        header 'Authorization', :Authorization
        let(:project) { { project: { name: 'Test Project', description: 'This is only a test project' } } }

        run_test!
      end

      response '422', 'invalid request' do
        header 'Authorization', :Authorization
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
        header 'Authorization', :Authorization
        let(:project) { create(:project, user: user) }
        let(:id) { project.id }

        run_test!
      end

      response '404', 'project not found' do
        header 'Authorization', :Authorization
        let(:id) { 999 }

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
        header 'Authorization', :Authorization
        let(:project_record) { create(:project, user: user) }
        let(:id) { project_record.id }
        let(:project) { { project: { name: 'Updated Project' } } }

        run_test!
      end

      response '404', 'project not found' do
        header 'Authorization', :Authorization
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
        header 'Authorization', :Authorization
        let(:project) { create(:project, user: user) }
        let(:id) { project.id }

        run_test!
      end

      response '404', 'project not found' do
        header 'Authorization', :Authorization
        let(:user1) { create(:user) }
        let(:project) { create(:project, user: user1) }
        let(:id) { project.id }

        run_test!
      end
    end
  end
end