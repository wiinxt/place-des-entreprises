# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DiagnosedNeed, type: :model do
  describe 'validations' do
    it do
      is_expected.to belong_to :diagnosis
      is_expected.to belong_to :question
      is_expected.to have_many :matches
      is_expected.to validate_presence_of :diagnosis
    end
  end

  describe 'question uniqueness in the scope of a diagnosis' do
    subject { build :diagnosed_need, diagnosis: diagnosis, question: question }

    let(:diagnosis) { create :diagnosis }
    let(:question) { create :question }

    context 'unique diagnosed_need for this question' do
      it { is_expected.to be_valid }
    end

    context 'diagnosed_need for another question' do
      before { create :diagnosed_need, diagnosis: diagnosis, question: question2 }

      let(:question2) { create :question }

      it { is_expected.to be_valid }
    end

    context 'diagnosed_need for the same question' do
      before { create :diagnosed_need, diagnosis: diagnosis, question: question }

      it { is_expected.not_to be_valid }
    end

    context 'several diagnosed_needs for a nil question' do
      before { create :diagnosed_need, diagnosis: diagnosis, question: nil }

      let(:question) { nil }

      it { is_expected.to be_valid }
    end
  end

  describe 'scopes' do
    describe 'of_diagnosis' do
      subject { DiagnosedNeed.of_diagnosis diagnosis }

      let(:diagnosis) { create :diagnosis }
      let(:diagnosed_need) { create :diagnosed_need, diagnosis: diagnosis }

      it { is_expected.to eq [diagnosed_need] }
    end

    describe 'of_question' do
      subject { DiagnosedNeed.of_question question }

      let(:question) { create :question }
      let(:diagnosed_need) { create :diagnosed_need, question: question }

      it { is_expected.to eq [diagnosed_need] }
    end

    describe 'with_at_least_one_expert_done' do
      subject { DiagnosedNeed.with_at_least_one_expert_done }

      let(:diagnosed_need) { create :diagnosed_need }

      before { create :diagnosed_need }

      context 'no expert done' do
        before do
          create :match, :with_assistance_expert, diagnosed_need: diagnosed_need, status: :quo
        end

        it { is_expected.to eq [] }
      end

      context 'two experts done for the same need' do
        before do
          create :match, :with_assistance_expert, diagnosed_need: diagnosed_need, status: :done
          create :match, :with_assistance_expert, diagnosed_need: diagnosed_need, status: :done
        end

        it { is_expected.to eq [diagnosed_need] }
      end
    end
  end
end
