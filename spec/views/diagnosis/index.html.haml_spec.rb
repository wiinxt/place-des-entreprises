# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'diagnosis/index.html.haml', type: :view do
  before do
    category = create :category
    create_list :question, 2, category: category
    render
  end

  it('displays a title') { expect(rendered).to match(/Diagnostic/) }
  it('displays one category title') { assert_select 'h2', count: 1 }
  it('displays two list elements') { assert_select 'tr', count: 2 }
end
