require 'rails_helper'

RSpec.describe Tag, type: :model do
  describe 'associations' do
    it { should have_many(:task_tags).dependent(:destroy) }
    it { should have_many(:tasks).through(:task_tags) }
  end

  describe 'callbacks' do
    context '#downcase_name' do
      it 'saves downcase tag name' do
        tag = create(:tag, name: 'TAG1')
        expect(tag.name).to eq('tag1')
      end
    end
  end
end
