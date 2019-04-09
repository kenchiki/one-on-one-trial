# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Basic Scenario', type: :system, js: true do
  let(:sent_mail) { ActionMailer::Base.deliveries.last }
  let(:sent_mail_body) { sent_mail.body.raw_source }

  before do
    # rails_helper.rbかconfig/environments/test.rbに書ける
    # capybaraではURLをIPアドレスで書いてしまうので設定している
    # hostみなくていいのでは？（相対パスでチェック）
    # 正規表現で対応できるが少し大変
    #
    # https://github.com/email-spec/email-spec（このgemを使えば回避できる可能性がある。採用実績がある）
    # https://github.com/email-spec/email-spec/blob/master/lib/email_spec/helpers.rb（helper使ってスマートに書ける）
    url_options = {
      host: Capybara.current_session.server.host,
      port: Capybara.current_session.server.port
    }

    Rails.application.routes.default_url_options = url_options
    ActionMailer::Base.default_url_options = url_options
  end

  it 'is able to register question & answer.' do
    # login_as(user, scope: :user)を使ってログインさせる（factory_botでuser作って）
    # すでにomniauth_login_spec.rbでテストしているのでここでのログインチェックは不要
    visit root_url
    expect(page).to have_content '1 ON 1'

    click_on 'Signin with Google'
    sleep 1
    expect(page).to have_content 'Google アカウントによる認証に成功しました。'
    expect(page).to have_content 'Login as john@example.com'

    click_on '質問ボードを作成する'
    expect(current_path).to eq new_loggedin_question_board_path
    expect(page).to have_content '質問ボードを作成する'
    # i18nで書き換える場合は何か別の手段でチェックする方がいいかも
    # 基本文字列で、name属性でだいたいチェックしてる
    expect(page).to have_field 'Title', with: nil

    # classを追加してチェックする方がシンプルになりそう
    question_block = find(:xpath, "//p[text()='質問']/following-sibling::div[@class='form-inputs']")
    expect(question_block).to have_link '質問を追加する'
    expect(question_block).to have_no_field

    fill_in 'Title', with: 'Basic Questions'

    # どこまで細かくテストを書くのか
    # バグ0より早く直せるかを目指すか
    # 質問は3つ必要ないかもしれない（大きな違いがあるなら分けた方がいいcontextなどで分ける）
    # このコード量なら2つくらい
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

    # save_and_open_pageを使用すればそのページがそのタイミングでブラウザが開くのでデバッグに便利
    # rubymineでもしかしたらスクリーンショットを確認できる機能があるかも
    # FIXME: remove remarks
    # save_screenshot: u can save the screenshot to tmp/capybara/*.png

    click_on '登録する'
    question_board = QuestionBoard.last

    # FIXME: IDを含むURIの、よりよい判定方法はないか？
    # idをとらずにlastを直接彫り込む
    # 登録できましたか何かの文字列でhave_contentするとシンプルかも
    # controllerだけで完結できるものはcontroller specを書くが、基本はsystemの方でやってしまう
    # systemの方でパスもチェックする
    # current_pathのチェックはSGではよくしている
    expect(current_path).to eq loggedin_question_board_path(question_board)
    expect(page).to have_content 'Basic Questions'
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'
    expect(page).to have_content 'Is this 3rd question?'

    click_on '戻る'

    expect(current_path).to eq loggedin_question_boards_path
    expect(page).to have_content 'Basic Questions'

    # 一つしか存在していないので、Basic Questionsを辿らずにシンプルにかけるかもしれない
    # 複数あってもclassで最後のものを参照するような書き方でもいいかも
    question_row = find(:xpath, "//a[text()='Basic Questions']/parent::td/parent::tr")
    question_row.click_on '回答してもらう'

    # オブジェクトを入れる
    expect(current_path).to eq new_loggedin_question_board_answer_board_path(question_board)
    expect(page).to have_field 'Email', with: nil

    fill_in 'Email', with: 'ada@example.com'
    click_on '送信する'

    expect(current_path).to eq loggedin_question_boards_path

    # last!の!をとる
    answer_board_token = AnswerBoard.last.token
    answer_board_url = edit_answer_board_url(token: answer_board_token)

    expect(sent_mail.subject).to eq '[1 ON 1] Johnさんより質問事項が届いています'
    expect(sent_mail.to.first).to eq 'ada@example.com'
    expect(sent_mail.from.first).to eq 'from@example.com'
    # メールは一部だけチェックする方がシンプル
    # answer_board_urlが含まれているかが重要
    # email-specもgemのhelperでチェックすることができる
    expect(sent_mail_body).to eq "1 ON 1サービスより質問事項が届いています。\r\n以下のURLにアクセスして、ご回答をお願いいたします。\r\n#{answer_board_url}\r\n\r\n"

    click_on 'ログアウト'
    expect(current_path).to eq login_index_path
    expect(page).to have_content 'ログアウトしました。'

    # セクションを分ける（質問すると回答するで分ける）
    # 分けた方が問題の切り分けがしやすくなる
    # 今回のシステムはシンプルだからなんとかなっているが大きくなると分ける方がメンテナンスしやすい
    # .rspecに`--format documentation`をいれるとspecの出力結果が仕様書のように見やすくなる（セクションを分けたのがより見やすくなる）
    # セクションを分けると落ちた箇所が特定しやすくなる（回答までうまくいったかなどがわかる）
    # 切り分けすぎるとシナリオにならなくなる
    # 作成、編集などの単位で分ける
    visit answer_board_url

    expect(page).to have_content '質問に回答する'
    expect(page).to have_field 'Name', with: nil
    expect(page).to have_content 'Is this 1st question?'
    expect(page).to have_content 'Is this 2nd question?'
    expect(page).to have_content 'Is this 3rd question?'

    # question1.find('textarea').fillでフィールドがなければ落ちるのでexpect(question1).to have_fieldしなくてもいいかも？
    # 作るのは大丈夫だが、直したりするのに負担がかかりそう
    # CIが落ちたら直すくらい
    # バグを直すのが早いかテストを厳密にするか
    # 最初は薄く、徐々にテストを増やしてく 、バグった時は、そこを手厚く書く
    # SGではタイプが別れている（鉄壁タイプか効率を求めるか）
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

    # 同じことを5〜6とか繰り返すのであれば共通箇所をまとめるけど、少しならDRYにしないかな
    # 記事が作成できること、記事にタグがつけられること、記事を編集できることみたいな単位で切り分けることがある
    # シナリオの長さが長くても50〜60行（チェックする項目が減る、質問する人、回答する人で分ける）
    # データの登録はfactory_botでtraitでデータを作る
  end
end
