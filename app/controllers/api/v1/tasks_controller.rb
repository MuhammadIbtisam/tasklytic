module Api
  module V1
    class TasksController < ApplicationController
      before_action :authenticate_user!
      before_action :set_task, only: [:show, :update, :destroy]

      def index
        page = params[:page].to_i
        unless page.positive?
          return render json: { error: 'page parameter must be positive integer' }, status: :bad_request
        end
        
        per_page = [params[:per_page]&.to_i || 10, 50].min
        tasks = current_user.tasks
        
        # Filter by status if provided
        if params[:status].present?
          tasks = tasks.where(status: params[:status])
        end
        
        # Filter by project_id if provided
        if params[:project_id].present?
          tasks = tasks.where(project_id: params[:project_id])
        end
        
        # Filter by due_type if provided
        if params[:due_type].present?
          case params[:due_type]
          when 'overdue'
            tasks = tasks.where('due_date < ?', Date.current)
          when 'due_today'
            tasks = tasks.where(due_date: Date.current)
          when 'due_this_week'
            tasks = tasks.where(due_date: Date.current..1.week.from_now)
          end
        end
        
        tasks = tasks.order(created_at: :desc).page(page).per(per_page)

        render json: {
          tasks: tasks,
          meta: {
            page: tasks.current_page,
            per_page: tasks.limit_value,
            total: tasks.total_count,
            total_pages: tasks.total_pages
          }
        }, status: :ok
      end

      def create
        task = current_user.tasks.build(task_params)
        if task.save
          render json: task, status: :created
        else
          render json: { errors: task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def show
        render json: @task, status: :ok
      end

      def update
        if @task.update(task_params)
          render json: @task, status: :ok
        else
          render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        @task.destroy
        head :no_content
      end

      private

      def set_task
        @task = current_user.tasks.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Task not found' }, status: :not_found
      end

      def task_params
        params.require(:task).permit(:title, :description, :status, :priority, :estimated_minutes, :due_date, :project_id)
      end
    end
  end
end