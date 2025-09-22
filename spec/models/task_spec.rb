require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
    it { should have_many(:task_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:task_tags) }
    it { should have_many(:focus_sessions).dependent(:destroy) }

    describe 'association behavior' do
      let(:task) { create(:task) }
      let(:tag) { create(:tag) }

      it 'destroys associated task_tags when task is destroyed' do
        task_tag = create(:task_tag, task: task, tag: tag)
        expect { task.destroy }.to change { TaskTag.count }.by(-1)
      end

      it 'destroys associated focus_sessions when task is destroyed' do
        focus_session = create(:focus_session, task: task)
        expect { task.destroy }.to change { FocusSession.count }.by(-1)
      end
    end
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:due_date) }
    it { should validate_presence_of(:priority) }

    describe 'title validation' do
      it 'rejects empty title' do
        task = build(:task, title: '')
        expect(task).not_to be_valid
        expect(task.errors[:title]).to include("can't be blank")
      end

      it 'rejects nil title' do
        task = build(:task, title: nil)
        expect(task).not_to be_valid
        expect(task.errors[:title]).to include("can't be blank")
      end

      it 'accepts valid title' do
        task = build(:task, title: 'Valid Task Title')
        expect(task).to be_valid
      end
    end

    describe 'status validation' do
      it 'rejects invalid status' do
        expect { build(:task, status: 'invalid_status') }.to raise_error(ArgumentError, "'invalid_status' is not a valid status")
      end

      it 'accepts valid statuses' do
        %w[pending in_progress completed cancelled].each do |status|
          task = build(:task, status: status)
          expect(task).to be_valid, "Status #{status} should be valid"
        end
      end
    end

    describe 'priority validation' do
      it 'rejects invalid priority' do
        expect { build(:task, priority: 'invalid_priority') }.to raise_error(ArgumentError, "'invalid_priority' is not a valid priority")
      end

      it 'accepts valid priorities' do
        %w[low medium high urgent].each do |priority|
          task = build(:task, priority: priority)
          expect(task).to be_valid, "Priority #{priority} should be valid"
        end
      end
    end

    describe 'due_date validation' do
      it 'rejects nil due_date' do
        task = build(:task, due_date: nil)
        expect(task).not_to be_valid
        expect(task.errors[:due_date]).to include("can't be blank")
      end

      it 'accepts valid due_date' do
        task = build(:task, due_date: 1.week.from_now)
        expect(task).to be_valid
      end
    end
  end

  describe 'enums' do
    describe 'status enum' do
      it 'defines correct status values' do
        expect(Task.statuses).to eq({
          'pending' => 0,
          'in_progress' => 1,
          'completed' => 2,
          'cancelled' => 3
        })
      end

      it 'provides status helper methods' do
        task = create(:task, status: :pending)
        expect(task.pending?).to be true
        expect(task.in_progress?).to be false
        expect(task.completed?).to be false
        expect(task.cancelled?).to be false
      end
    end

    describe 'priority enum' do
      it 'defines correct priority values' do
        expect(Task.priorities).to eq({
          'low' => 0,
          'medium' => 1,
          'high' => 2,
          'urgent' => 3
        })
      end

      it 'provides priority helper methods' do
        task = create(:task, priority: :high)
        expect(task.low?).to be false
        expect(task.medium?).to be false
        expect(task.high?).to be true
        expect(task.urgent?).to be false
      end
    end
  end

  describe 'scopes' do
    describe '.overdue' do
      it 'returns overdue tasks that are not completed' do
        overdue_task = create(:task, due_date: 2.days.ago, status: :pending)
        completed_overdue_task = create(:task, due_date: 2.days.ago, status: :completed)
        today_task = create(:task, due_date: 1.hour.from_now, status: :pending)
        tomorrow_task = create(:task, due_date: 1.day.from_now, status: :pending)
        
        overdue_tasks = Task.overdue
        expect(overdue_tasks).to include(overdue_task)
        expect(overdue_tasks).not_to include(completed_overdue_task)
        expect(overdue_tasks).not_to include(today_task)
        expect(overdue_tasks).not_to include(tomorrow_task)
      end

      it 'excludes tasks due today or in the future' do
        today_task = create(:task, due_date: 1.hour.from_now, status: :pending)
        tomorrow_task = create(:task, due_date: 1.day.from_now, status: :pending)
        
        overdue_tasks = Task.overdue
        expect(overdue_tasks).not_to include(today_task)
        expect(overdue_tasks).not_to include(tomorrow_task)
      end
    end

    describe '.due_today' do
      it 'returns tasks due today' do
        overdue_task = create(:task, due_date: 2.days.ago, status: :pending)
        today_task = create(:task, due_date: Time.current.beginning_of_day, status: :pending)
        tomorrow_task = create(:task, due_date: 1.day.from_now, status: :pending)
        
        due_today_tasks = Task.due_today
        expect(due_today_tasks).to include(today_task)
        expect(due_today_tasks).not_to include(overdue_task)
        expect(due_today_tasks).not_to include(tomorrow_task)
      end

      it 'includes tasks due within the current day range' do
        morning_task = create(:task, due_date: Time.current.beginning_of_day, status: :pending)
        evening_task = create(:task, due_date: Time.current.end_of_day, status: :pending)
        
        due_today_tasks = Task.due_today
        expect(due_today_tasks).to include(morning_task)
        expect(due_today_tasks).to include(evening_task)
      end
    end

    describe '.due_this_week' do
      it 'returns tasks due within the current week' do
        overdue_task = create(:task, due_date: 2.weeks.ago, status: :pending)
        today_task = create(:task, due_date: Time.current.beginning_of_day, status: :pending)
        tomorrow_task = create(:task, due_date: Time.current.end_of_week - 1.day, status: :pending) # Within current week
        next_week_task = create(:task, due_date: 1.week.from_now, status: :pending)
        
        due_this_week_tasks = Task.due_this_week
        expect(due_this_week_tasks).to include(today_task)
        expect(due_this_week_tasks).to include(tomorrow_task)
        expect(due_this_week_tasks).not_to include(overdue_task)
        expect(due_this_week_tasks).not_to include(next_week_task)
      end
    end
  end

  describe '#total_focus_time' do
    let(:task) { create(:task) }

    it 'returns the sum of all focus session durations' do
      create(:focus_session, task: task, duration_minutes: 30)
      create(:focus_session, task: task, duration_minutes: 45)
      create(:focus_session, task: task, duration_minutes: 15)
      expect(task.total_focus_time).to eq(90)
    end

    it 'returns 0 if there are no focus sessions' do
      expect(task.total_focus_time).to eq(0)
    end

    it 'handles focus sessions with zero duration' do
      create(:focus_session, task: task, duration_minutes: 0)
      create(:focus_session, task: task, duration_minutes: 30)
      expect(task.total_focus_time).to eq(30)
    end

    it 'handles negative durations (edge case)' do
      create(:focus_session, task: task, duration_minutes: -10)
      create(:focus_session, task: task, duration_minutes: 30)
      expect(task.total_focus_time).to eq(20)
    end
  end

  describe '#estimated_vs_actual_time' do
    let(:task) { create(:task) }

    it 'returns nil if estimated_minutes is nil' do
      task = build(:task, estimated_minutes: nil)
      allow(task).to receive(:total_focus_time).and_return(10)
      expect(task.estimated_vs_actual_time).to be_nil
    end

    it 'returns nil if total_focus_time is 0' do
      task = build(:task, estimated_minutes: 10)
      allow(task).to receive(:total_focus_time).and_return(0)
      expect(task.estimated_vs_actual_time).to be_nil
    end

    it 'returns the correct percentage when actual time is less than estimated' do
      task = build(:task, estimated_minutes: 40)
      allow(task).to receive(:total_focus_time).and_return(20)
      expect(task.estimated_vs_actual_time).to eq(50.0)
    end

    it 'returns the correct percentage when actual time equals estimated' do
      task = build(:task, estimated_minutes: 40)
      allow(task).to receive(:total_focus_time).and_return(40)
      expect(task.estimated_vs_actual_time).to eq(100.0)
    end

    it 'returns the correct percentage when actual time exceeds estimated' do
      task = build(:task, estimated_minutes: 30)
      allow(task).to receive(:total_focus_time).and_return(60)
      expect(task.estimated_vs_actual_time).to eq(200.0)
    end

    it 'rounds the percentage to 1 decimal place' do
      task = build(:task, estimated_minutes: 33)
      allow(task).to receive(:total_focus_time).and_return(10)
      expect(task.estimated_vs_actual_time).to eq(30.3)
    end

    it 'handles edge case with very small estimated_minutes' do
      task = build(:task, estimated_minutes: 1)
      allow(task).to receive(:total_focus_time).and_return(3)
      expect(task.estimated_vs_actual_time).to eq(300.0)
    end
  end

  describe 'callbacks and lifecycle' do
    it 'can be created with valid attributes' do
      task = build(:task)
      expect(task).to be_valid
      expect(task.save).to be true
    end

    it 'can be updated with valid attributes' do
      task = create(:task, title: 'Original Title')
      task.title = 'Updated Title'
      expect(task.save).to be true
      expect(task.reload.title).to eq('Updated Title')
    end

    it 'can be destroyed' do
      task = create(:task)
      expect { task.destroy }.to change { Task.count }.by(-1)
      expect(Task.find_by(id: task.id)).to be_nil
    end
  end

  describe 'factory' do
    it 'creates a valid task' do
      task = create(:task)
      expect(task).to be_valid
      expect(task.title).to be_present
      expect(task.description).to be_present
      expect(task.project).to be_present
      expect(task.user).to be_present
      expect(task.priority).to eq('medium')
      expect(task.status).to eq('pending')
      expect(task.due_date).to be_present
      expect(task.estimated_minutes).to eq(60)
    end
  end
end
