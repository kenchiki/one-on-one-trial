# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'OmniAuth Login', type: :system do
  it 'is able to login with Google account.' do
    visit root_url
    # どこにでも表示していてもOKになってしまうのでヘッダー部分、フッター部分などのおおざっぱに指定を入れる
    # expect(find('#header')).to have_content '1 ON 1'
    expect(page).to have_content '1 ON 1'


    # お客様がi18nを書き換える仕組みがSGであるので、その場合はhave_contentを使用せずにclass、idなどを使う方がいいかもしれない
    # spec〜のようなclass名をつけている
    # data-test="twitter_click"みたいに影響与えない属性を追加してやってました


    # 時間がかかるコストを考えて、have_contentを使用している
    click_on 'Signin with Google'

    # 基本的にsleepやretryは入れない方が良い
    # https://qiita.com/shunichi/items/1cb7f7cfca74438513d3#%E3%82%AF%E3%83%AA%E3%83%83%E3%82%AF%E3%81%AE%E5%BE%8C%E3%81%AB%E3%83%9A%E3%83%BC%E3%82%B8%E9%81%B7%E7%A7%BB%E3%82%92%E5%BE%85%E3%81%9F%E3%81%9A%E3%81%AB-visit-%E3%81%97%E3%81%A6%E3%82%8B
    # 基本的に、ページ遷移をhave_contentをすると待ってくれる仕様（要検証）なのでsleepは不要かも
    #
    # https://github.com/mataki/dekiru
    # ajaxの処理を待つdekiru gem
    sleep 1
    expect(page).to have_content 'Google アカウントによる認証に成功しました。'
    expect(page).to have_content 'Login as john@example.com'

    click_on 'ログアウト'
    expect(current_path).to eq '/login/index'
    expect(page).to have_content 'ログアウトしました。'
  end
end
