module Api
  module V1
    class ProjectsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_project, only: [:show, :update, :destroy]

      def index
        page = params[:page].to_i
        unless page.positive?
          return render json: { error: 'page parameter must be positive integer' }, status: :bad_request
        end
        per_page = [params[:per_page]&.to_i || 10, 50].min
        projects = if params[:user_id].present?
          Project.where(user_id: params[:user_id]).order(created_at: :desc).page(page).per(per_page)
        else
          Project.order(created_at: :desc).page(page).per(per_page)
        end

        render json: {
          projects: projects,
          meta: {
            page: projects.current_page,
            per_page: projects.limit_value,
            total: projects.total_count,
            total_pages: projects.total_pages
          }
        }, status: :ok
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
        render json: {
          project: @project,
          tasks: @project.tasks,
          user_name: @project.user.full_name
        }, status: :ok
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