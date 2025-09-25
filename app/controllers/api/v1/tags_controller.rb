module Api
  module V1
    class TagsController < ApplicationController
      before_action :authenticate_user!
      before_action :set_tag, only: [:show, :update, :destroy]

      def index
        page = params[:page].to_i
        unless page.positive?
          return render json: { error: 'page parameter must be positive integer' }, status: :bad_request
        end

        per_page = [params[:per_page]&.to_i || 10, 50].min
        tags = Tag.all

        # Filter by search term if provided
        if params[:search].present?
          tags = tags.where('name ILIKE ?', "%#{params[:search]}%")
        end

        # Filter by user's tags only if specified
        if params[:user_only] == 'true'
          user_task_ids = current_user.tasks.pluck(:id)
          tags = tags.joins(:task_tags).where(task_tags: { task_id: user_task_ids }).distinct
        end

        # Sort options
        case params[:sort]
        when 'name'
          tags = tags.order(:name)
        when 'usage_count'
          tags = tags.left_joins(:task_tags)
                    .group('tags.id')
                    .order('COUNT(task_tags.id) DESC')
        when 'created_at'
          tags = tags.order(created_at: :desc)
        else
          tags = tags.order(:name) # default sort
        end

        tags = tags.page(page).per(per_page)

        render json: {
          tags: tags,
          meta: {
            page: tags.current_page,
            per_page: tags.limit_value,
            total: tags.total_count,
            total_pages: tags.total_pages
          }
        }, status: :ok
      end

      def show
        render json: {
          tag: @tag,
          usage_count: @tag.task_tags.count,
          tasks: @tag.tasks.where(user: current_user).limit(10)
        }, status: :ok
      end

      def create
        tag = Tag.find_or_initialize_by(name: tag_params[:name].downcase)
        
        if tag.persisted?
          render json: { 
            message: 'Tag already exists',
            tag: tag 
          }, status: :ok
        elsif tag.save
          render json: tag, status: :created
        else
          render json: { errors: tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def update
        if @tag.update(tag_params)
          render json: @tag, status: :ok
        else
          render json: { errors: @tag.errors.full_messages }, status: :unprocessable_entity
        end
      end

      def destroy
        if @tag.task_tags.any?
          return render json: { 
            error: 'Cannot delete tag that is assigned to tasks. Please remove all task assignments first.' 
          }, status: :unprocessable_entity
        end

        @tag.destroy
        head :no_content
      end

      # Get popular tags (most used by current user)
      def popular
        limit = [params[:limit]&.to_i || 10, 50].min
        
        user_task_ids = current_user.tasks.pluck(:id)
        popular_tags = Tag.joins(:task_tags)
                          .where(task_tags: { task_id: user_task_ids })
                          .group('tags.id, tags.name')
                          .order('COUNT(task_tags.id) DESC')
                          .limit(limit)
                          .pluck('tags.id, tags.name, COUNT(task_tags.id)')

        render json: {
          popular_tags: popular_tags.map do |id, name, count|
            {
              id: id,
              name: name,
              usage_count: count
            }
          end
        }, status: :ok
      end

      # Get tags for a specific task
      def for_task
        task = current_user.tasks.find(params[:task_id])
        render json: task.tags, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Task not found' }, status: :not_found
      end

      # Assign tags to a task
      def assign_to_task
        task = current_user.tasks.find(params[:task_id])
        tag_names = params[:tag_names] || []
        
        # Find or create tags
        tags = tag_names.map do |tag_name|
          Tag.find_or_create_by(name: tag_name.downcase.strip)
        end

        # Assign tags to task
        task.tags = tags
        
        render json: {
          message: 'Tags assigned successfully',
          task: task,
          tags: task.tags
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Task not found' }, status: :not_found
      end

      # Remove tags from a task
      def remove_from_task
        task = current_user.tasks.find(params[:task_id])
        tag_ids = params[:tag_ids] || []
        
        task.tags.delete(Tag.where(id: tag_ids))
        
        render json: {
          message: 'Tags removed successfully',
          task: task,
          tags: task.tags
        }, status: :ok
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Task not found' }, status: :not_found
      end

      # Get tag statistics
      def stats
        user_task_ids = current_user.tasks.pluck(:id)
        
        total_tags = Tag.joins(:task_tags)
                        .where(task_tags: { task_id: user_task_ids })
                        .distinct
                        .count

        most_used_tag = Tag.joins(:task_tags)
                           .where(task_tags: { task_id: user_task_ids })
                           .group('tags.id, tags.name')
                           .order('COUNT(task_tags.id) DESC')
                           .first

        tags_without_tasks = Tag.left_joins(:task_tags)
                                .where(task_tags: { id: nil })
                                .count

        render json: {
          total_tags_used: total_tags,
          most_used_tag: most_used_tag ? {
            id: most_used_tag.id,
            name: most_used_tag.name,
            usage_count: most_used_tag.task_tags.where(task_id: user_task_ids).count
          } : nil,
          unused_tags_count: tags_without_tasks
        }, status: :ok
      end

      private

      def set_tag
        @tag = Tag.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { error: 'Tag not found' }, status: :not_found
      end

      def tag_params
        params.require(:tag).permit(:name)
      end
    end
  end
end
