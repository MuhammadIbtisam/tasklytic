module Api
  module V1
    class ProjectsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_project, only: [:show, :update, :destroy]

      def index
        projects = current_user.projects
        render json: projects, status: :ok
      end

      def create
        project = current_user.projects.build(project_params)
        if project.save
          render json: project, status: :created
        else
          render json: { errors: project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        render json: @project, status: :ok
      end

      def update
        if @project.update(project_params)
          render json: @project, status: :ok
        else
          render json: { errors: @project.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @project.destroy
        head :no_content
      end

      private

      def set_project
        @project = current_user.projects.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Project not found' }, status: :not_found
      end

      def project_params
        params.require(:project).permit(:name, :description)
      end
    end
  end
end