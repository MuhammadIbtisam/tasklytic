require 'rails_helper'

RSpec.describe Task, type: :model do
  describe 'associations' do
    it { should belong_to(:project) }
    it { should belong_to(:user) }
    it { should have_many(:task_tags).dependent(:destroy) }
    it { should have_many(:tags).through(:task_tags) }
    it { should have_many(:focus_sessions).dependent(:destroy) } # fixed typo
  end

  describe 'validations' do
    it { should validate_presence_of(:title) }
    it { should validate_presence_of(:status) }
    it { should validate_presence_of(:due_date) }
    it { should validate_presence_of(:priority) }
  end

  describe 'scopes' do
    let!(:overdue_task) { create(:task, due_date: 2.days.ago, status: :pending) }
    let!(:completed_task) { create(:task, due_date: 2.days.ago, status: :completed) }
    let!(:today_task) { create(:task, due_date: 1.hour.from_now, status: :pending) }

    it 'returns overdue tasks that are not completed' do
      expect(Task.overdue).to include(overdue_task)
      expect(Task.overdue).not_to include(completed_task)
      expect(Task.overdue).not_to include(today_task)
    end

    it 'returns tasks due today' do
      expect(Task.due_today).to include(today_task)
    end
  end

  describe '#total_focus_time' do
    it 'returns the sum of all focus session durations' do
      task = create(:task)
      create(:focus_session, task: task, duration_minutes: 30)
      create(:focus_session, task: task, duration_minutes: 45)
      expect(task.total_focus_time).to eq(75)
    end

    it 'returns 0 if there are no focus sessions' do
      task = create(:task)
      expect(task.total_focus_time).to eq(0)
    end
  end

  describe '#estimated_vs_actual_time' do
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

    it 'returns the correct percentage if both values are present' do
      task = build(:task, estimated_minutes: 40)
      allow(task).to receive(:total_focus_time).and_return(20)
      expect(task.estimated_vs_actual_time).to eq(50.0)
    end
  end
end
