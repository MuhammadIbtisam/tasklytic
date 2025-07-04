class TasksController < ApplicationController
  before_action :authenticate_user!
  before_action :set_task, only: [:show, :update, :destroy]

  def index
    @tasks = current_user.tasks
    @tasks = @tasks.where(project_id: params[:project_id]) if params[:project_id]
    @tasks = @tasks.where(status: params[:status]) if params[:status]
    @tasks = @tasks.order(priority: :desc, due_date: :asc)
    
    render json: @tasks
  end

  def show
    render json: @task
  end

  def create
    @task = current_user.tasks.build(task_params)
    
    if @task.save
      render json: @task, status: :created
    else
      render json: { errors: @task.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def update
    if @task.update(task_params)
      render json: @task
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
  end

  def task_params
    params.require(:task).permit(:title, :description, :project_id, :priority, 
                                :estimated_minutes, :status, :due_date, tag_ids: [])
  end
end 