# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OmniAuth Login', type: :system do
  it 'is able to login with Google account.' do
    visit root_url
    expect(page).to have_content '1 ON 1'

    click_on 'Signin with Google'
    sleep 1
    expect(page).to have_content 'Google アカウントによる認証に成功しました。'
    expect(page).to have_content 'Login as john@example.com'

    click_on 'ログアウト'
    expect(current_path).to eq '/login/index'
    expect(page).to have_content 'ログアウトしました。'
  end
end
