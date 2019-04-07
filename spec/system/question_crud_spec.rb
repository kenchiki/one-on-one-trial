# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Question CRUD', type: :system, js: true do
  before do
    Rails.application.routes.default_url_options = {
      host: Capybara.current_session.server.host,
      port: Capybara.current_session.server.port
    }
  end

  before do
    visit root_url
    expect(page).to have_content '1 ON 1'

    click_on 'Signin with Google'
    sleep 1
    expect(page).to have_content 'Login as john@example.com'
  end

  it 'is able to CRUD question.' do
    click_on '質問ボードを作成する'
    expect(current_path).to eq new_loggedin_question_board_path
    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")

    fill_in 'Title', with: 'CRUD Testing'

    click_on '質問を追加する'
    expect(question_block).to have_field
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 1
    expect(question_fields.last.value).to be_blank
    question_fields.last.fill_in with: 'Is this 1st question?'

    click_on '質問を追加する'
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 2
    expect(question_fields.last.value).to be_blank
    question_fields.last.fill_in with: 'Is this 2nd question?'

    click_on '登録する'
    question_board_id = QuestionBoard.last!.id

    # FIXME: is there nice method to verify uri?
    expect(current_path).to eq loggedin_question_board_path(question_board_id)
    expect(page).to have_content 'Question board was successfully created.'
    expect(page).to have_content 'CRUD Testing'
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'

    click_on '戻る'

    expect(current_path).to eq loggedin_question_boards_path
    expect(page).to have_link 'CRUD Testing'

    click_on 'CRUD Testing'

    expect(current_path).to eq loggedin_question_board_path(question_board_id)
    expect(page).to have_content 'CRUD Testing'
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'

    click_on '戻る'

    question_row = find(:xpath, "//a[text()='CRUD Testing']/parent::td/parent::tr")
    question_row.click_on '編集'

    expect(current_path).to eq edit_loggedin_question_board_path(question_board_id)
    expect(page).to have_field 'Title', with: 'CRUD Testing'
    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 2
    expect(question_fields[0].value).to eq 'Is this 1st question?'
    expect(question_fields[1].value).to eq 'Is this 2nd question?'

    fill_in 'Title', with: 'CRUD Question Board (edited)'

    click_on '質問を追加する'
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 3
    expect(question_fields.last.value).to be_blank
    question_fields.last.fill_in with: 'Is this 3rd (added) question?'

    question_fields[0].fill_in with: 'Is this FIRST (edited) question?'

    question_fields[1].find(:xpath, '../..').click_on '削除'
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 2
    expect(question_fields).to have_no_field with: 'Is this 2nd question?'

    click_on '更新する'

    expect(current_path).to eq loggedin_question_board_path(question_board_id)
    expect(page).to have_content 'Question board was successfully updated.'
    expect(page).to have_content 'CRUD Question Board (edited)'
    expect(page).to have_content 'Is this FIRST (edited) question?'
    expect(page).to have_no_content 'Is this 2nd question?'
    expect(page).to have_content 'Is this 3rd (added) question?'

    click_on '編集する'

    expect(current_path).to eq edit_loggedin_question_board_path(question_board_id)
    expect(page).to have_field 'Title', with: 'CRUD Question Board (edited)'
    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 2
    expect(question_fields[0].value).to eq 'Is this FIRST (edited) question?'
    expect(question_fields[1].value).to eq 'Is this 3rd (added) question?'

    # FIXME: リンク網羅は別のシナリオでやったほうがいい？
    click_on '詳細'

    expect(current_path).to eq loggedin_question_board_path(question_board_id)

    click_on '編集する'

    expect(current_path).to eq edit_loggedin_question_board_path(question_board_id)

    click_on '戻る'

    expect(current_path).to eq loggedin_question_boards_path
    expect(page).to have_link 'CRUD Question Board (edited)'

    question_row = find(:xpath, "//a[text()='CRUD Question Board (edited)']/parent::td/parent::tr")
    question_row.click_on '削除'
    expect(page.driver.browser.switch_to.alert.text).to eq 'Are you sure?'

    page.driver.browser.switch_to.alert.dismiss
    expect(page).to have_link 'CRUD Question Board (edited)'

    question_row = find(:xpath, "//a[text()='CRUD Question Board (edited)']/parent::td/parent::tr")
    question_row.click_on '削除'
    page.driver.browser.switch_to.alert.accept
    expect(page).to have_no_link 'CRUD Question Board (edited)'
  end
end
