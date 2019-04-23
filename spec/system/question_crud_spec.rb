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

    # expect(page).to have_content '1 ON 1'
    expect(find('#header')).to have_content '1 ON 1'

    click_on 'Signin with Google'
    sleep 1
    expect(page).to have_content 'Login as john@example.com'
  end

  # 日本語で書くのかはプロジェクトによる
  # systemテストではdescribeを使うことが多い
  # itを使うのは違和感
  # itでもsnarioでも動作は一緒なので、合ってるものを使う方が良いかも
  it 'is able to CRUD question.' do
    # リンクにしているのかボタンにするのかはどちらになっても修正する必要がない
    click_on '質問ボードを作成する'

    expect(current_path).to eq new_loggedin_question_board_path
    expect(page).to have_content '質問ボードを作成する'
    expect(page).to have_field 'Title', with: nil

    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    expect(question_block).to have_link '質問を追加する'
    expect(question_block).to have_no_field

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
    question_board = QuestionBoard.last

    # FIXME: is there nice method to verify uri?
    expect(current_path).to eq loggedin_question_board_path(question_board)
    expect(page).to have_content 'Question board was successfully created.'
    expect(page).to have_content 'CRUD Testing'
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'

    click_on '戻る'

    expect(current_path).to eq loggedin_question_boards_path
    expect(page).to have_link 'CRUD Testing'

    click_on 'CRUD Testing'

    expect(current_path).to eq loggedin_question_board_path(question_board)
    expect(page).to have_content 'CRUD Testing'
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'

    click_on '戻る'

    question_row = find(:xpath, "//a[text()='CRUD Testing']/parent::td/parent::tr")
    question_row.click_on '編集'

    expect(current_path).to eq edit_loggedin_question_board_path(question_board)
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

    expect(current_path).to eq loggedin_question_board_path(question_board)
    expect(page).to have_content 'Question board was successfully updated.'
    expect(page).to have_content 'CRUD Question Board (edited)'
    expect(page).to have_content 'Is this FIRST (edited) question?'
    expect(page).to have_no_content 'Is this 2nd question?'
    expect(page).to have_content 'Is this 3rd (added) question?'

    click_on '編集する'

    expect(current_path).to eq edit_loggedin_question_board_path(question_board)
    expect(page).to have_field 'Title', with: 'CRUD Question Board (edited)'
    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 2
    expect(question_fields[0].value).to eq 'Is this FIRST (edited) question?'
    expect(question_fields[1].value).to eq 'Is this 3rd (added) question?'

    # FIXME: リンク網羅は別のシナリオでやったほうがいい？
    # 別のシナリオに分けることで同じチェックをしなくてもいいのではないか？
    # プロジェクトの規模とか人数でテストの粒度が変わってくる
    # 一人で開発しているのならざっと動作しているかのチェックでいいかも
    # 境界チェックは小さいスコープで書くと良い
    # 閲覧権限などはフィーチャースペックで書いても良い
    # APIのテストならリクエストも書くことがある
    # 基本的にはsystemとmodelだけ書くことが多い
    # 不安だった場合はその適切なテストを書く（helperなど）
    # 処理が複雑だったら書くことはある（helper）
    # テスト書くときはTTDのために書くときと不安な時に書くことが多い
    click_on '詳細'

    expect(current_path).to eq loggedin_question_board_path(question_board)

    click_on '編集する'

    expect(current_path).to eq edit_loggedin_question_board_path(question_board)

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

  # バリデーションはsystemスペックで書かないことがある
  # エラーが出ているかどうかをチェックする場合のみのことがある
  # バリデーションも不安のある場合は書く
  it 'is able to validate question title.' do
    click_on '質問ボードを作成する'
    expect(current_path).to eq new_loggedin_question_board_path
    expect(page).to have_content '質問ボードを作成する'
    expect(page).to have_field 'Title', with: nil

    click_on '登録する'

    expect(page).to have_selector 'div.alert', text: 'Please review the problems below:'

    # capybaraにsiblingというメソッドがあるので要検証
    feedback = find_field('Title').find(:xpath, "./following-sibling::div[@class='invalid-feedback']")
    expect(feedback.text).to eq 'Titleを入力してください'

    fill_in 'Title', with: 'Validation Testing'

    click_on '登録する'
    question_board_id = QuestionBoard.last!.id

    expect(current_path).to eq loggedin_question_board_path(question_board_id)
    expect(page).to have_content 'Question board was successfully created.'
    expect(page).to have_content 'Validation Testing'
  end
end
