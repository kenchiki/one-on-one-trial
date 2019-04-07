# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Basic Scenario', type: :system, js: true do
  let(:sent_mail) { ActionMailer::Base.deliveries.last }
  let(:sent_mail_body) { sent_mail.body.raw_source }

  before do
    url_options = {
      host: Capybara.current_session.server.host,
      port: Capybara.current_session.server.port
    }
    Rails.application.routes.default_url_options = url_options
    ActionMailer::Base.default_url_options = url_options
  end

  it 'is able to register question & answer.' do
    visit root_url
    expect(page).to have_content '1 ON 1'

    click_on 'Signin with Google'
    sleep 1
    expect(page).to have_content 'Google アカウントによる認証に成功しました。'
    expect(page).to have_content 'Login as john@example.com'

    click_on '質問ボードを作成する'
    expect(current_path).to eq new_loggedin_question_board_path
    expect(page).to have_content '質問ボードを作成する'
    expect(page).to have_field 'Title', with: nil

    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    expect(question_block).to have_link '質問を追加する'
    expect(question_block).to have_no_field

    fill_in 'Title', with: 'Basic Questions'

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

    click_on '質問を追加する'
    question_fields = question_block.all("input[type='text']")
    expect(question_fields.count).to eq 3
    expect(question_fields.last.value).to be_blank
    question_fields.last.fill_in with: 'Is this 3rd question?'

    # FIXME: remove remarks
    # save_screenshot: u can save the screenshot to tmp/capybara/*.png

    click_on '登録する'
    question_board_id = QuestionBoard.last!.id

    # FIXME: IDを含むURIの、よりよい判定方法はないか？
    expect(current_path).to eq loggedin_question_board_path(question_board_id)
    expect(page).to have_content 'Basic Questions'
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'
    expect(page).to have_content 'Is this 3rd question?'

    click_on '戻る'

    expect(current_path).to eq loggedin_question_boards_path
    expect(page).to have_content 'Basic Questions'

    question_row = find(:xpath, "//a[text()='Basic Questions']/parent::td/parent::tr")
    question_row.click_on '回答してもらう'
  
    expect(current_path).to eq new_loggedin_question_board_answer_board_path(question_board_id)
    expect(page).to have_field 'Email', with: nil

    fill_in 'Email', with: 'ada@example.com'
    click_on '送信する'

    expect(current_path).to eq loggedin_question_boards_path

    answer_board_token = AnswerBoard.last!.token
    answer_board_url = edit_answer_board_url(token: answer_board_token)

    expect(sent_mail.subject).to eq '[1 ON 1] Johnさんより質問事項が届いています'
    expect(sent_mail.to.first).to eq 'ada@example.com'
    expect(sent_mail.from.first).to eq 'from@example.com'
    expect(sent_mail_body).to eq "1 ON 1サービスより質問事項が届いています。\r\n以下のURLにアクセスして、ご回答をお願いいたします。\r\n#{answer_board_url}\r\n\r\n"

    click_on 'ログアウト'
    expect(current_path).to eq login_index_path
    expect(page).to have_content 'ログアウトしました。'

    visit answer_board_url

    expect(page).to have_content '質問に回答する'
    expect(page).to have_field 'Name', with: nil
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'
    expect(page).to have_content 'Is this 3rd question?'

    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    expect(question_block).to have_selector 'textarea', count: 3
    question1 = question_block.find(:xpath, "./p[text()='Is this 1st question?']/following-sibling::div[position()=1]")
    expect(question1).to have_field with: nil
    question2 = question_block.find(:xpath, "./p[text()='Is this 2nd question?']/following-sibling::div[position()=1]")
    expect(question2).to have_field with: nil
    question3 = question_block.find(:xpath, "./p[text()='Is this 3rd question?']/following-sibling::div[position()=1]")
    expect(question3).to have_field with: nil

    fill_in 'Name', with: 'Ada Wong'
    question1.find('textarea').fill_in with: '1st answer.'
    question2.find('textarea').fill_in with: '2nd answer.'
    question3.find('textarea').fill_in with: '3rd answer.'

    click_on '回答を登録する'

    expect(current_path).to eq answer_board_path(token: answer_board_token)
    expect(page).to have_content 'Answer board was successfully updated.'
    expect(page).to have_content 'ada@example.com'
    expect(page).to have_content 'Ada Wong'
    expect(page).to have_content '1st answer.'
    expect(page).to have_content '2nd answer.'
    expect(page).to have_content '3rd answer.'

    click_on '再編集'
  
    expect(current_path).to eq edit_answer_board_path(token: answer_board_token)
    expect(page).to have_field 'Name', with: 'Ada Wong'

    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    question1 = question_block.find(:xpath, "./p[text()='Is this 1st question?']/following-sibling::div[position()=1]")
    expect(question1).to have_field with: '1st answer.'
    question2 = question_block.find(:xpath, "./p[text()='Is this 2nd question?']/following-sibling::div[position()=1]")
    expect(question2).to have_field with: '2nd answer.'
    question3 = question_block.find(:xpath, "./p[text()='Is this 3rd question?']/following-sibling::div[position()=1]")
    expect(question3).to have_field with: '3rd answer.'

    fill_in 'Name', with: 'エイダ・ウォン'
    question1.find('textarea').fill_in with: '最初の答え'
    question3.find('textarea').fill_in with: '最後の答え'

    click_on '回答を登録する'

    expect(current_path).to eq answer_board_path(token: answer_board_token)
    expect(page).to have_content 'Answer board was successfully updated.'
    expect(page).to have_content 'ada@example.com'
    expect(page).to have_content 'エイダ・ウォン'
    expect(page).to have_content '最初の答え'
    expect(page).to have_content '2nd answer.'
    expect(page).to have_content '最後の答え'
  end
end
